import SpriteKit

@MainActor
final class DelveGameSession {
    enum Action { case enter, continueFloor, equip, clear, extract, death, abandon }
    private enum Event { case hit(Double), kill(UUID), recover(Double) }

    let store: DelveSaveStore
    private(set) var stats: DelveCharacterStats
    private(set) var metrics: DelveCombatMetrics?
    private(set) var busy = false
    private(set) var gameplayPaused = true
    private(set) var error: Error?
    weak var controller: FloorViewController?
    var onCommit: ((Action) -> Void)?
    var onError: ((Error) -> Void)?
    var onPause: (() -> Void)?
    private var events = [Event]()
    private var bossDefeated = false
    private var pending: DelvePreparedSave<Void>?
    private var pendingAction: Action?
    private var pendingOperationID: UUID?
    private var snapshotInFlight = false
    private var anotherSnapshotRequested = false
    private var lastSaveClock = 0.0

    init(store: DelveSaveStore) throws {
        self.store = store
        stats = try store.progression.characterStats()
        metrics = store.progression.activeRun?.floor.world?.metrics
        if let run = store.progression.activeRun, run.floor.phase == .combat, run.floor.world == nil {
            throw DelveError.invalidValue("missing live combat snapshot")
        }
    }

    var progression: DelveProgression { store.progression }
    var health: Double { progression.activeRun?.resources.health ?? stats.maxHealth }
    var shield: Double { progression.activeRun?.resources.shield ?? stats.maxShield }
    var alive: Bool { !busy && (progression.activeRun?.resources.health ?? 0) > 0 }

    func enter() async throws {
        var random = DelveRandom(seed: UInt64.random(in: UInt64.min...UInt64.max))
        try await perform(.enter) {
            try $0.enterDungeon(using: &random)
            let world = try DelveWorldFactory.initialWorld(for: $0, random: random)
            try $0.updateWorld(world, floorID: world.floorID)
        }
    }

    func continueFloor() async throws {
        guard let run = progression.activeRun else { throw DelveError.invalidTransition }
        var random = run.floor.world?.random ?? DelveRandom(seed: UInt64.random(in: UInt64.min...UInt64.max))
        try await perform(.continueFloor) {
            try $0.continueRun(after: run.floor.id, using: &random)
            let world = try DelveWorldFactory.initialWorld(for: $0, random: random)
            try $0.updateWorld(world, floorID: world.floorID)
        }
    }

    func equip(_ itemID: UUID?, in slot: DelveEquipmentSlot) async throws {
        try await perform(.equip) { try $0.equipItem(itemID, in: slot) }
    }

    func extract() async throws {
        guard let run = progression.activeRun else { throw DelveError.invalidTransition }
        try await perform(.extract) { try $0.extract(runID: run.id) }
    }

    func abandon() async throws {
        guard let run = progression.activeRun else { throw DelveError.invalidTransition }
        if let room = controller?.scene { flush(room) }
        guard !busy else { throw DelveSaveError.pendingTransaction }
        try await perform(.abandon) { try $0.abandon(floorID: run.floor.id) }
    }

    func makeController() throws -> FloorViewController {
        guard !busy, let run = progression.activeRun, run.floor.phase == .combat,
              let world = run.floor.world else { throw DelveError.invalidTransition }
        let floor = try FloorViewController(plan: run.floor.plan, restorableCombat: true, world: world)
        controller = floor
        floor.delveSession = self
        gameplayPaused = true
        metrics = world.metrics
        lastSaveClock = world.clock
        return floor
    }

    func receiveHit(_ rawDamage: Double) { if !busy { events.append(.hit(rawDamage)) } }
    func killed(_ enemyID: UUID) { if !busy { events.append(.kill(enemyID)) } }
    func killedBoss() { if !busy { bossDefeated = true } }
    func recoverShield(_ amount: Double) { if !busy { events.append(.recover(amount)) } }

    func fired(_ id: UUID, in room: RoomScene) {
        guard combatIsLive(room), !busy else { return }
        metrics?.shots.fired(id)
    }

    func resolved(_ id: UUID, hit: Bool) { metrics?.shots.resolve(id, hit: hit) }

    func recordFrame(_ room: RoomScene) {
        guard !busy, !gameplayPaused, !room.isPaused else { return }
        do { try metrics?.recordTime(seconds: room.frameDuration, combatIsLive: combatIsLive(room)) }
        catch { fail(error) }
    }

    private func combatIsLive(_ room: RoomScene) -> Bool {
        room.started && !room.completed && room.entites.contains {
            ($0 as? EnemyEntity).map { $0.currentHealth > 0 } ?? ($0 as? BossEntity).map { $0.currentHealth > 0 } ?? false
        }
    }

    // Contact callbacks queue one frame's events. Publish resources, XP and the
    // post-physics world together, so a killed actor can never be saved alive.
    func flush(_ room: RoomScene) {
        guard !busy, controller?.scene === room,
              let run = progression.activeRun, run.floor.phase == .combat,
              let catalog = room.combatStats, var measurements = metrics else { return }
        do {
            var next = progression
            var defeated = events.compactMap { event -> UUID? in if case .kill(let id) = event { return id }; return nil }
            if bossDefeated { defeated.append(run.floor.plan.rooms.last!.id) }
            for event in events {
                guard let before = next.activeRun else { break }
                switch event {
                case .hit(let raw):
                    let capacity = before.resources.health + before.resources.shield
                    try next.receiveHit(floorID: run.floor.id, rawDamage: raw, defeatedInFrame: defeated)
                    let remaining = next.activeRun.map { $0.resources.health + $0.resources.shield } ?? 0
                    try measurements.recordDamage(capacity - remaining)
                case .kill(let id): try next.awardKill(floorID: run.floor.id, enemyID: id)
                case .recover(let amount): try next.recover(floorID: run.floor.id, shield: amount)
                }
            }
            if room.completed { measurements.shots.finishCombat() }
            let action: Action?
            if next.activeRun == nil { action = .death }
            else if bossDefeated {
                try next.finishFloor(floorID: run.floor.id, performance: measurements.performance(), using: &room.combatRandom)
                action = .clear
            } else {
                let completed = Set(controller!.plannedRooms.values.filter(\.completed).compactMap { $0.plannedRoom?.id })
                let world = try DelveWorldBridge.capture(room: room, floorID: run.floor.id,
                    completed: completed, stats: catalog, metrics: measurements)
                try next.updateWorld(world, floorID: run.floor.id)
                action = nil
            }
            if let action = action {
                try prepare(action) { $0 = next }
                events.removeAll(); bossDefeated = false; metrics = measurements
                Task { try? await retryPending() }
            } else {
                try store.stageCombat { $0 = next }
                events.removeAll(); metrics = measurements
                stats = try progression.characterStats()
                Player.entity.component(ofType: HealthBarComponent.self)?.updateBars(shield, health: health)
                if room.time - lastSaveClock >= 1 { lastSaveClock = room.time; saveSnapshot() }
            }
        } catch { fail(error) }
    }

    func suspend() {
        gameplayPaused = true
        guard let room = controller?.scene else { return }
        room.isPaused = true
        controller?.skView.isPaused = true
        stopControls()
        flush(room)
        saveSnapshot()
    }

    func requestPause() { onPause?() }

    private func stopControls() {
        Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.resetInput()
        Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.resetInput()
        Player.entity.stopControls()
        #if targetEnvironment(macCatalyst)
        controller?.scene?.resetKeyboardControls()
        #endif
    }

    func resume() {
        guard !busy, error == nil, progression.activeRun?.floor.phase == .combat else { return }
        gameplayPaused = false
        controller?.skView.isPaused = false
        controller?.scene?.isPaused = false
    }

    func saveSnapshot() {
        guard !busy, store.hasUnsavedCombat else { return }
        if snapshotInFlight { anotherSnapshotRequested = true; return }
        snapshotInFlight = true
        Task {
            defer { snapshotInFlight = false }
            // A critical candidate already includes the newest world. An
            // autosave queued before it was prepared must not report its lock
            // as an I/O failure or try to write over the checkpoint.
            guard !busy else { return }
            do {
                repeat {
                    anotherSnapshotRequested = false
                    try await store.saveCombat()
                } while anotherSnapshotRequested && !busy && store.hasUnsavedCombat
            }
            catch { fail(error) }
        }
    }

    func retrySave() async throws {
        if pending != nil { try await retryPending(); return }
        do {
            try await store.saveCombat()
            error = nil
        } catch {
            fail(error)
            throw error
        }
    }

    private func perform(_ action: Action, change: (inout DelveProgression) throws -> Void) async throws {
        try prepare(action, change: change)
        try await retryPending()
    }

    private func prepare(_ action: Action, change: (inout DelveProgression) throws -> Void) throws {
        guard !busy else { throw DelveSaveError.pendingTransaction }
        pending = try store.prepare(change)
        pendingAction = action
        pendingOperationID = UUID()
        busy = true
        gameplayPaused = true
        controller?.scene?.isPaused = true
        stopControls()
    }

    private func retryPending() async throws {
        guard let token = pending, let action = pendingAction, let operationID = pendingOperationID else { return }
        do {
            try await store.commit(token)
            guard pendingOperationID == operationID else { return }
            pending = nil; pendingAction = nil; pendingOperationID = nil
            busy = false; error = nil
            stats = try progression.characterStats()
            onCommit?(action)
        } catch {
            fail(error)
            throw error
        }
    }

    private func fail(_ error: Error) {
        self.error = error
        gameplayPaused = true
        controller?.scene?.isPaused = true
        stopControls()
        onError?(error)
    }
}
