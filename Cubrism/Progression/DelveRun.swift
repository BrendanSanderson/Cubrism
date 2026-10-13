import Foundation

enum DelveItemKind: String, Codable {
    case powerCore, armorCore, pulsar, specialPulsar, shield, attachment
}

enum DelveEquipmentSlot: String, Codable, CaseIterable {
    case powerCore, armorCore, pulsar, specialPulsar, shield, attachmentOne, attachmentTwo

    func accepts(_ kind: DelveItemKind) -> Bool {
        switch self {
        case .attachmentOne, .attachmentTwo: return kind == .attachment
        default: return rawValue == kind.rawValue
        }
    }
}

struct DelveLoot: Codable, Equatable {
    let id: UUID
    let kind: DelveItemKind
    let power: Double
    let rarity: DelveRarity
    let variant: Int
    let attachmentStat: String?

    init(id: UUID = UUID(), kind: DelveItemKind, power: Double, rarity: DelveRarity,
         variant: Int = 0, attachmentStat: String? = nil) throws {
        try DelveRules.validateScore(power)
        guard (0...3).contains(variant) else { throw DelveError.invalidLoot }
        let attachmentStats = ["AttackPower", "Defence", "Shield", "Health"]
        guard kind == .attachment ? attachmentStats.contains(attachmentStat ?? "") : attachmentStat == nil else {
            throw DelveError.invalidLoot
        }
        self.id = id
        self.kind = kind
        self.power = power
        self.rarity = rarity
        self.variant = variant
        self.attachmentStat = attachmentStat
    }
}

struct DelveExperience: Codable, Equatable {
    let levelUpCosts: [Double]
    private(set) var level = 1
    private(set) var progress = 0.0
    private(set) var lifetime = 0.0
    var cap: Int { levelUpCosts.count + 1 }

    // Supply the calibrated fixed costs at the composition boundary. A v1
    // account supplies 99 costs for the selected level-100 cap. Tests can use
    // a shorter progression; no final reward/cost curve is invented here.
    init(levelUpCosts: [Double]) throws {
        guard !levelUpCosts.isEmpty,
              levelUpCosts.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw DelveError.invalidValue("XP costs")
        }
        self.levelUpCosts = levelUpCosts
    }

    mutating func award(_ amount: Double) throws {
        guard amount.isFinite, amount >= 0, (lifetime + amount).isFinite else {
            throw DelveError.invalidValue("XP")
        }
        lifetime += amount
        guard level < cap else { return }
        progress += amount
        while level < cap, progress >= levelUpCosts[level - 1] {
            progress -= levelUpCosts[level - 1]
            level += 1
        }
        // Lifetime is historical accounting, never a bank for future levels.
        if level == cap { progress = 0 }
    }
}

struct DelveResources: Codable, Equatable {
    private(set) var health: Double
    private(set) var shield: Double
    private(set) var maxHealth: Double
    private(set) var maxShield: Double
    private(set) var peakHealth: Double
    private(set) var peakShield: Double

    init(maxHealth: Double, maxShield: Double) throws {
        guard maxHealth.isFinite, maxHealth > 0, maxShield.isFinite, maxShield >= 0 else {
            throw DelveError.invalidValue("capacity")
        }
        health = maxHealth
        shield = maxShield
        self.maxHealth = maxHealth
        self.maxShield = maxShield
        peakHealth = maxHealth
        peakShield = maxShield
    }

    mutating func changeCapacity(health newHealth: Double, shield newShield: Double) throws {
        guard newHealth.isFinite, newHealth > 0, newShield.isFinite, newShield >= 0 else {
            throw DelveError.invalidValue("capacity")
        }
        health = min(newHealth, health + max(0, newHealth - peakHealth))
        shield = min(newShield, shield + max(0, newShield - peakShield))
        maxHealth = newHealth
        maxShield = newShield
        peakHealth = max(peakHealth, newHealth)
        peakShield = max(peakShield, newShield)
    }

    mutating func takeDamage(_ amount: Double) throws {
        guard amount.isFinite, amount >= 0 else { throw DelveError.invalidValue("damage") }
        let absorbed = min(shield, amount)
        shield -= absorbed
        health = max(0, health - (amount - absorbed))
    }

    mutating func recover(health amount: Double, shield shieldAmount: Double) throws {
        guard [amount, shieldAmount].allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw DelveError.invalidValue("recovery")
        }
        health += min(maxHealth - health, amount)
        shield += min(maxShield - shield, shieldAmount)
    }

    mutating func enterNextFloor() { shield = maxShield }
}

enum DelveFloorPhase: String, Codable { case combat, checkpoint }
enum DelveRunEnd: String, Codable { case extracted, died, abandoned }

struct DelveFloorAttempt: Codable, Equatable {
    let id: UUID
    let entryRating: Double
    let difficulty: Double
    let plan: DelveFloorPlan
    fileprivate(set) var phase: DelveFloorPhase = .combat
    fileprivate(set) var awardedXPEvents: Set<UUID> = []
    fileprivate(set) var rewardIDs: [UUID] = []
}

struct DelveActiveRun: Codable, Equatable {
    let id: UUID
    fileprivate(set) var depth: Int
    fileprivate(set) var floor: DelveFloorAttempt
    fileprivate(set) var resources: DelveResources
    fileprivate(set) var loot: [DelveLoot] = []
    // Banked replacements remain owned; a failed run restores this loadout.
    let bankedLoadout: [DelveEquipmentSlot: UUID]
}

struct DelveRunSettlement: Codable, Equatable {
    let runID: UUID
    let outcome: DelveRunEnd
}

// This snapshot owns account progression and run reward/resource state in one
// value. DelveSaveStore persists this value atomically. Live encounters and
// projectiles still need scene integration; this alone is not full combat resume.
struct DelveProgression: Codable, Equatable {
    private(set) var rating: Double
    private(set) var experience: DelveExperience
    private(set) var bankedItems: [DelveLoot]
    private(set) var equipped: [DelveEquipmentSlot: UUID]
    private(set) var activeRun: DelveActiveRun?
    private(set) var lastSettlement: DelveRunSettlement?
    let rules: DelveRules

    init(rating: Double = 1, levelUpCosts: [Double], bankedItems: [DelveLoot] = [],
         equipped: [DelveEquipmentSlot: UUID] = [:], rules: DelveRules = DelveRules()) throws {
        try DelveRules.validateScore(rating)
        try rules.validate()
        guard Set(bankedItems.map(\.id)).count == bankedItems.count else { throw DelveError.invalidLoot }
        try Self.validateLoadout(equipped, items: bankedItems)
        self.rating = rating
        experience = try DelveExperience(levelUpCosts: levelUpCosts)
        self.bankedItems = bankedItems
        self.equipped = equipped
        self.rules = rules
    }

    private static func validateLoadout(_ slots: [DelveEquipmentSlot: UUID], items: [DelveLoot]) throws {
        guard Set(slots.values).count == slots.count else { throw DelveError.invalidEquipment }
        for (slot, id) in slots {
            guard let item = items.first(where: { $0.id == id }), slot.accepts(item.kind) else {
                throw DelveError.invalidEquipment
            }
        }
    }

    // Synthesized Codable decoding bypasses our initializers. Validate every
    // loaded value before gameplay can index XP costs or act on saved ownership.
    func validateSnapshot() throws {
        try DelveRules.validateScore(rating)
        try rules.validate()
        try experience.validateSnapshot()
        let items = bankedItems + (activeRun?.loot ?? [])
        guard Set(items.map(\.id)).count == items.count else { throw DelveError.invalidLoot }
        for item in items {
            _ = try DelveLoot(id: item.id, kind: item.kind, power: item.power, rarity: item.rarity,
                             variant: item.variant, attachmentStat: item.attachmentStat)
        }
        try Self.validateLoadout(equipped, items: items)
        guard let run = activeRun else { return }
        guard run.depth >= 1, run.id != lastSettlement?.runID else {
            throw DelveError.invalidValue("run")
        }
        try DelveRules.validateScore(run.floor.entryRating)
        try DelveRules.validateScore(run.floor.difficulty)
        try run.floor.plan.validate()
        guard run.floor.plan.difficulty == run.floor.difficulty else {
            throw DelveError.invalidValue("floor difficulty")
        }
        try run.resources.validateSnapshot()
        try Self.validateLoadout(run.bankedLoadout, items: bankedItems)

        // Each completed floor must still own its unbanked rewards. Use Double
        // for count bounds so a malformed Int.max depth cannot overflow here.
        let cleared = Double(run.depth - (run.floor.phase == .combat ? 1 : 0))
        let minimumLoot = 2 * min(cleared, 5) + 3 * max(0, cleared - 5)
        let maximumLoot = cleared == 0 ? 0 : 2 + 3 * (cleared - 1)
        guard Double(run.loot.count) >= minimumLoot, Double(run.loot.count) <= maximumLoot else {
            throw DelveError.invalidLoot
        }
        switch run.floor.phase {
        case .combat:
            guard rating == run.floor.entryRating,
                  run.floor.rewardIDs.isEmpty,
                  run.depth != 1 || equipped == run.bankedLoadout else {
                throw DelveError.invalidValue("combat state")
            }
        case .checkpoint:
            let rewardCount = run.floor.rewardIDs.count
            let allowedCount = run.depth == 1 ? 2...2 : (run.depth >= 6 ? 3...3 : 2...3)
            let rewards = run.loot.suffix(rewardCount)
            guard allowedCount.contains(rewardCount), rewards.map(\.id) == run.floor.rewardIDs,
                  rewards.allSatisfy({ $0.power == run.floor.difficulty }) else {
                throw DelveError.invalidLoot
            }
            let low = try rules.winGain(entryRating: run.floor.entryRating, difficulty: run.floor.difficulty,
                                        depth: run.depth, performance: DelvePerformance(speed: 0, accuracy: 0, avoidance: 0))
            let high = try rules.winGain(entryRating: run.floor.entryRating, difficulty: run.floor.difficulty,
                                         depth: run.depth, performance: DelvePerformance(speed: 1, accuracy: 1, avoidance: 1))
            let tolerance = max(1, rating) * 1e-12
            guard rating >= run.floor.entryRating + low - tolerance,
                  rating <= run.floor.entryRating + high + tolerance else {
                throw DelveError.invalidValue("checkpoint state")
            }
        }
    }

    private func combatRun(floorID: UUID) throws -> DelveActiveRun {
        guard let run = activeRun, run.floor.id == floorID else { throw DelveError.staleFloor }
        guard run.floor.phase == .combat else { throw DelveError.invalidTransition }
        return run
    }

    @discardableResult
    mutating func startRun<R: RandomNumberGenerator>(maxHealth: Double, maxShield: Double,
                                                     using random: inout R) throws -> UUID {
        guard activeRun == nil else { throw DelveError.invalidTransition }
        let resources = try DelveResources(maxHealth: maxHealth, maxShield: maxShield)
        let difficulty = try rules.sampleDifficulty(rating: rating, using: &random)
        let plan = try DelveFloorPlanner().generate(difficulty: difficulty, using: &random)
        let floor = DelveFloorAttempt(id: UUID(), entryRating: rating, difficulty: difficulty, plan: plan)
        activeRun = DelveActiveRun(id: UUID(), depth: 1, floor: floor, resources: resources,
                                  bankedLoadout: equipped)
        return floor.id
    }

    @discardableResult
    mutating func awardXP(floorID: UUID, eventID: UUID, baseAmount: Double) throws -> Bool {
        var run = try combatRun(floorID: floorID)
        guard !run.floor.awardedXPEvents.contains(eventID) else { return false }
        let bonus = try DelveRules.continuationBonus(depth: run.depth)
        // Work on a copy so a rejected reward cannot partially mutate account XP.
        var updatedXP = experience
        try updatedXP.award(baseAmount * (1 + bonus))
        run.floor.awardedXPEvents.insert(eventID)
        experience = updatedXP
        activeRun = run
        return true
    }

    @discardableResult
    mutating func clearFloor(floorID: UUID, performance: DelvePerformance, loot: [DelveLoot]) throws -> Bool {
        guard var run = activeRun, run.floor.id == floorID else { throw DelveError.staleFloor }
        guard run.floor.phase == .combat else { return false }
        let allowedCount = run.depth == 1 ? 2...2 : (run.depth >= 6 ? 3...3 : 2...3)
        let ownedIDs = Set((bankedItems + run.loot).map(\.id))
        guard allowedCount.contains(loot.count), Set(loot.map(\.id)).count == loot.count,
              loot.allSatisfy({ !ownedIDs.contains($0.id) && $0.power == run.floor.difficulty }) else {
            throw DelveError.invalidLoot
        }
        let gain = try rules.winGain(entryRating: run.floor.entryRating, difficulty: run.floor.difficulty,
                                     depth: run.depth, performance: performance)
        guard (rating + gain).isFinite else { throw DelveError.invalidValue("rating") }
        run.loot += loot
        run.floor.rewardIDs = loot.map(\.id)
        run.floor.phase = .checkpoint
        rating += gain
        activeRun = run
        return true
    }

    @discardableResult
    mutating func continueRun<R: RandomNumberGenerator>(after floorID: UUID,
                                                        using random: inout R) throws -> UUID {
        guard var run = activeRun, run.floor.id == floorID else { throw DelveError.staleFloor }
        guard run.floor.phase == .checkpoint, run.depth < Int.max else { throw DelveError.invalidTransition }
        let difficulty = try rules.sampleDifficulty(rating: rating, using: &random)
        let plan = try DelveFloorPlanner().generate(difficulty: difficulty, using: &random)
        run.floor = DelveFloorAttempt(id: UUID(), entryRating: rating, difficulty: difficulty, plan: plan)
        run.depth += 1
        run.resources.enterNextFloor()
        activeRun = run
        return run.floor.id
    }

    mutating func equip(_ itemID: UUID?, in slot: DelveEquipmentSlot,
                        maxHealth: Double, maxShield: Double) throws {
        // Capacity values come from the real equipment/stat calculator during
        // integration. Ownership and peak-capacity healing are enforced here.
        guard var run = activeRun, run.floor.phase == .checkpoint else { throw DelveError.invalidTransition }
        var next = equipped
        next[slot] = itemID
        try Self.validateLoadout(next, items: bankedItems + run.loot)
        try run.resources.changeCapacity(health: maxHealth, shield: maxShield)
        equipped = next
        activeRun = run
    }

    mutating func changeCapacity(floorID: UUID, maxHealth: Double, maxShield: Double) throws {
        guard var run = activeRun, run.floor.id == floorID else { throw DelveError.staleFloor }
        try run.resources.changeCapacity(health: maxHealth, shield: maxShield)
        activeRun = run
    }

    mutating func takeDamage(floorID: UUID, amount: Double) throws {
        var run = try combatRun(floorID: floorID)
        try run.resources.takeDamage(amount)
        if run.resources.health == 0 {
            try settleFailure(run, outcome: .died)
        } else {
            activeRun = run
        }
    }

    mutating func recover(floorID: UUID, health: Double = 0, shield: Double = 0) throws {
        var run = try combatRun(floorID: floorID)
        try run.resources.recover(health: health, shield: shield)
        activeRun = run
    }

    @discardableResult
    mutating func extract(runID: UUID) throws -> Bool {
        if activeRun == nil, lastSettlement?.runID == runID, lastSettlement?.outcome == .extracted { return false }
        guard let run = activeRun, run.id == runID, run.floor.phase == .checkpoint else {
            throw DelveError.invalidTransition
        }
        bankedItems += run.loot
        lastSettlement = DelveRunSettlement(runID: run.id, outcome: .extracted)
        activeRun = nil
        return true
    }

    mutating func abandon(floorID: UUID) throws {
        let run = try combatRun(floorID: floorID)
        try settleFailure(run, outcome: .abandoned)
    }

    private mutating func settleFailure(_ run: DelveActiveRun, outcome: DelveRunEnd) throws {
        let loss = try rules.loss(entryRating: run.floor.entryRating, difficulty: run.floor.difficulty)
        rating = max(1, rating - loss)
        equipped = run.bankedLoadout
        lastSettlement = DelveRunSettlement(runID: run.id, outcome: outcome)
        activeRun = nil
    }
}

private extension DelveExperience {
    func validateSnapshot() throws {
        _ = try DelveExperience(levelUpCosts: levelUpCosts)
        guard (1...cap).contains(level), progress.isFinite, progress >= 0,
              lifetime.isFinite, lifetime >= 0 else { throw DelveError.invalidValue("XP snapshot") }
        if level == cap {
            guard progress == 0 else { throw DelveError.invalidValue("capped XP") }
        } else {
            guard progress < levelUpCosts[level - 1] else { throw DelveError.invalidValue("XP progress") }
        }
        let earned = levelUpCosts.prefix(level - 1).reduce(progress, +)
        let tolerance = max(1, lifetime) * 1e-12
        guard earned.isFinite,
              level == cap ? lifetime >= earned - tolerance : abs(lifetime - earned) <= tolerance else {
            throw DelveError.invalidValue("lifetime XP")
        }
    }
}

private extension DelveResources {
    func validateSnapshot() throws {
        guard [health, shield, maxHealth, maxShield, peakHealth, peakShield].allSatisfy({ $0.isFinite }),
              maxHealth > 0, maxShield >= 0, health > 0, health <= maxHealth,
              shield >= 0, shield <= maxShield, peakHealth >= maxHealth, peakShield >= maxShield else {
            throw DelveError.invalidValue("resource snapshot")
        }
    }
}
