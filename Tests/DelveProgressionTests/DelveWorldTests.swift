import Foundation
import XCTest
@testable import CubrismProgression

final class DelveWorldTests: XCTestCase {
    private func fixture() throws -> (DelveProgression, DelveWorldState) {
        var account = try DelveProgression.freshAccount()
        var random = DelveRandom(seed: 854)
        let floor = try account.enterDungeon(using: &random)
        let plan = try XCTUnwrap(account.activeRun?.floor.plan)
        let balance = account.rules.balance
        let enemies = try Dictionary(uniqueKeysWithValues: DelveEnemyKind.allCases.map {
            ($0, try balance.enemyStats(difficulty: plan.difficulty, relative: DelveRelativeStats(), elite: $0.isElite))
        })
        let bosses = try Dictionary(uniqueKeysWithValues: DelveBossKind.allCases.map {
            ($0, try balance.enemyStats(difficulty: plan.difficulty, relative: DelveRelativeStats(), boss: true))
        })
        let catalog = DelveFloorCombatStats(enemies: enemies, bosses: bosses,
                                           fireball: try balance.enemyStats(difficulty: plan.difficulty, relative: DelveRelativeStats()))
        guard case .combat(let spawns) = plan.rooms[1].encounter else { throw DelveError.invalidTransition }
        let actors = spawns.map { spawn in
            DelveActorState(id: spawn.id, kind: .enemy(spawn.kind),
                pose: DelvePose(position: DelvePoint(x: spawn.position.x * 750, y: spawn.position.y * 375), width: 32, height: 32),
                health: enemies[spawn.kind]!.health * 0.55, stats: enemies[spawn.kind]!,
                behaviours: [.randomMovement(DelveMovementState(moving: true, target: DelvePoint(x: 400, y: 150), speed: 0.75)),
                             .targeted(DelveShootingState(lastShot: 49.5, cooldown: 1))])
        }
        let player = DelvePlayerState(pose: DelvePose(position: DelvePoint(x: 120, y: 160), width: 32, height: 32),
                                      cannonRotation: 0.7, lastHit: 49.75, lastShot: 49.8)
        var movement = try DelveLinearMotion(start: DelvePoint(x: 120, y: 160), destination: DelvePoint(x: 500, y: 200), duration: 1.5)
        try movement.advance(seconds: 0.7)
        let sprite = UUID()
        let motion = try DelveMotionState(id: sprite, movement: movement, lingerSeconds: 0.05)
        let shot = UUID(), container = shot
        var metrics = try DelveCombatMetrics(targetSeconds: 60, entryCapacity: 300)
        try metrics.recordTime(seconds: 20, combatIsLive: true)
        try metrics.recordDamage(50)
        metrics.shots.fired(shot)
        let world = DelveWorldState(floorID: floor, currentRoomID: plan.rooms[1].id,
            completedRoomIDs: [plan.rooms[0].id], clock: 50, started: true, random: random, stats: catalog,
            player: player, actors: actors,
            containers: [DelveProjectileContainer(id: container, position: DelvePoint(x: 0, y: 0), z: 0,
                                                  type: "player", playerShotID: shot, rangeDamage: 0, effectDamage: 0)],
            sprites: [DelveProjectileSprite(id: sprite, containerID: container, image: "playerShot",
                                           pose: DelvePose(position: movement.position, width: 8, height: 8), movement: motion, attached: true)],
            fuses: [], metrics: metrics)
        return (account, world)
    }

    func testCombatStateRoundTripKeepsPartialHealthTimersRNGShotsAndMovement() throws {
        var (account, world) = try fixture()
        try account.receiveHit(floorID: world.floorID, rawDamage: 80)
        try account.updateWorld(world, floorID: world.floorID)
        try account.validateSnapshot()
        let restored = try JSONDecoder().decode(DelveProgression.self, from: JSONEncoder().encode(account))
        try restored.validateSnapshot()
        XCTAssertEqual(restored, account)
        XCTAssertEqual(restored.activeRun?.floor.world, world)
        XCTAssertLessThan(try XCTUnwrap(restored.activeRun?.resources.shield), 140)
        var resumed = try XCTUnwrap(restored.activeRun?.floor.world)
        XCTAssertEqual(resumed.random.next(), world.random.next())
        XCTAssertEqual(resumed.player.lastHit, 49.75)
        XCTAssertEqual(resumed.player.lastShot, 49.8)
        var motion = try XCTUnwrap(resumed.sprites[0].movement)
        try motion.advance(seconds: 0.3)
        XCTAssertEqual(motion.movement.elapsed, 1, accuracy: 1e-12)
        XCTAssertEqual(resumed.metrics.shots.inFlight.count, 1)
    }

    func testKillStateAndActorSnapshotMustChangeTogether() throws {
        var (account, world) = try fixture()
        try account.updateWorld(world, floorID: world.floorID)
        let killed = try XCTUnwrap(world.actors.first).id
        try account.awardKill(floorID: world.floorID, enemyID: killed)
        XCTAssertThrowsError(try account.validateSnapshot(), "An awarded kill cannot restore as a living mob")
        world.actors.removeAll { $0.id == killed }
        if world.actors.isEmpty { world.completedRoomIDs.insert(world.currentRoomID) }
        try account.updateWorld(world, floorID: world.floorID)
        try account.validateSnapshot()
        XCTAssertFalse(try account.awardKill(floorID: world.floorID, enemyID: killed))
    }

    func testCorruptWorldCannotSkipRoomsOrInventActorsAndReferences() throws {
        let (account, original) = try fixture()
        let plan = try XCTUnwrap(account.activeRun?.floor.plan)
        for mutation in 0..<7 {
            var world = original
            switch mutation {
            case 0: world.currentRoomID = plan.rooms.last!.id
            case 1: world.completedRoomIDs = [plan.rooms[1].id]
            case 2: world.actors[0].health = world.actors[0].stats.health + 1
            case 3: world.actors[0].behaviours = [.tracking(speed: 1)]
            case 4: world.sprites[0] = DelveProjectileSprite(id: world.sprites[0].id, containerID: UUID(),
                                                            image: "playerShot", pose: world.sprites[0].pose, attached: true)
            case 5: world.metrics.shots.fired(UUID())
            default: world.actors.append(world.actors[0])
            }
            XCTAssertThrowsError(try world.validate(plan: plan), "Mutation \(mutation)")
        }
    }

    @MainActor func testCombatWorldIsWrittenAtomicallyWithAccountResourcesAndXP() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("delve.json")
        var (account, world) = try fixture()
        try account.updateWorld(world, floorID: world.floorID)
        let store = try DelveSaveStore(fileURL: file) { account }
        let victim = world.actors.removeFirst().id
        if world.actors.isEmpty { world.completedRoomIDs.insert(world.currentRoomID) }
        world.clock += 0.25
        world.player.lastHit = world.clock
        try world.metrics.recordDamage(79.925)
        _ = world.random.next()
        try store.stageCombat {
            try $0.receiveHit(floorID: world.floorID, rawDamage: 80)
            try $0.awardKill(floorID: world.floorID, enemyID: victim)
            try $0.updateWorld(world, floorID: world.floorID)
        }
        try await store.saveCombat()
        let reloaded = try DelveSaveStore(fileURL: file) {
            XCTFail("Combat reload cannot generate another account or floor")
            return account
        }
        XCTAssertEqual(reloaded.progression, store.progression)
        XCTAssertEqual(reloaded.progression.activeRun?.floor.world, world)
        XCTAssertTrue(try XCTUnwrap(reloaded.progression.activeRun?.floor.awardedXPEvents).contains(victim))
        XCTAssertLessThan(try XCTUnwrap(reloaded.progression.activeRun?.resources.shield), 140)
    }

    func testRockPhaseValidationRejectsUnrestorablePartialBursts() throws {
        let idle = DelveRockState(acting: false, shots: 6, lastShot: 5, startTime: 1,
                                 angles: [], velocities: [], spriteIDs: [])
        XCTAssertNoThrow(try idle.validate())
        for count in 0...6 {
            let state = DelveRockState(acting: true, shots: count, lastShot: 5, startTime: 1,
                angles: Array(repeating: 0.5, count: 6), velocities: Array(repeating: 2, count: 6),
                spriteIDs: (0..<count).map { _ in UUID() })
            XCTAssertNoThrow(try state.validate())
            var bad = state
            if count == 0 { bad.angles = []; bad.velocities = [] }
            else { bad.spriteIDs = [] }
            let decoded = try JSONDecoder().decode(DelveRockState.self, from: JSONEncoder().encode(bad))
            XCTAssertThrowsError(try decoded.validate(), "Invalid active burst with \(count) fired rocks")
        }
    }

    func testPartialBossPhaseRoundTripWithoutRestartingItsEffects() throws {
        var (account, world) = try fixture()
        let plan = try XCTUnwrap(account.activeRun?.floor.plan)
        let boss = try XCTUnwrap(plan.rooms.last)
        for enemy in plan.enemies { try account.awardKill(floorID: world.floorID, enemyID: enemy.id) }
        world.currentRoomID = boss.id
        world.completedRoomIDs = Set(plan.rooms.dropLast().map(\.id))
        guard case .boss(let kind) = boss.encounter else { throw DelveError.invalidTransition }
        let behaviours: [DelveBehaviourState]
        let selected: String
        switch kind {
        case .dragon:
            behaviours = [.bossTargeted(DelveShootingState(lastShot: 49, cooldown: 1, image: "bossDragonShot0")),
                          .breathe(DelveBurstState(acting: false, shots: 0, lastShot: 49)),
                          .fireball(acting: true, lastShot: 49.8, fired: false)]
            selected = "fireball"
        case .generator:
            behaviours = [.bossTargeted(DelveShootingState(lastShot: 49, cooldown: 1, image: "bossGeneratorShot")),
                          .spray(DelveBurstState(acting: true, shots: 12, lastShot: 49.8, angle: 0.5)),
                          .electric(DelveFieldState(acting: false, lastShot: 40))]
            selected = "spray"
        case .golem:
            behaviours = [.drop(DelveFieldState(acting: false, lastShot: 40)),
                          .rocks(DelveRockState(acting: true, shots: 0, lastShot: 49.8, startTime: 49.8,
                                               angles: Array(repeating: 0.5, count: 6), velocities: Array(repeating: 2, count: 6), spriteIDs: [])),
                          .jump(DelveJumpState(lastJump: 49, lastMove: 49.8, moves: 3, direction: 1)), .bossTracking(speed: 1.5)]
            selected = "rocks"
        }
        let stats = world.stats.bosses[kind]!
        world.actors = [DelveActorState(id: boss.id, kind: .boss(kind),
            pose: DelvePose(position: DelvePoint(x: 375, y: 180), width: 100, height: 100), health: stats.health * 0.6,
            stats: stats, behaviours: behaviours, bossPhase: DelveBossPhase(firstAttack: false, selectedAttack: selected, lastShot: 49.8))]
        try account.updateWorld(world, floorID: world.floorID)
        try account.validateSnapshot()
        let restored = try JSONDecoder().decode(DelveWorldState.self, from: JSONEncoder().encode(world))
        try restored.validate(plan: plan)
        XCTAssertEqual(restored, world)
        XCTAssertEqual(restored.actors[0].bossPhase?.selectedAttack, selected)
        var missingBoss = restored
        missingBoss.actors = []
        XCTAssertThrowsError(try missingBoss.validate(plan: plan), "Unfinished boss combat must preserve its boss")
    }
}
