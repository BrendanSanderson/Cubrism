import Foundation

struct DelveItemStats: Codable, Equatable {
    var attackPower = 0.0
    var health = 0.0
    var shield = 0.0
    var defence = 0.0
    var attackSpeed = 0.0
    var shieldRegen = 0.0

    func scaled(by factor: Double) -> Self {
        Self(attackPower: attackPower * factor, health: health * factor, shield: shield * factor,
             defence: defence * factor, attackSpeed: attackSpeed * factor, shieldRegen: shieldRegen * factor)
    }

    mutating func add(_ other: Self) {
        attackPower += other.attackPower
        health += other.health
        shield += other.shield
        defence += other.defence
        attackSpeed += other.attackSpeed
        shieldRegen += other.shieldRegen
    }
}

struct DelveCharacterStats: Codable, Equatable {
    let maxHealth: Double
    let maxShield: Double
    let attackPower: Double
    let flatArmour: Double
    let shotCooldown: Double
    let shieldRegen: Double
    var damagePerSecond: Double { attackPower / shotCooldown }
}

struct DelveRelativeStats: Equatable {
    var health = 1.0
    var range = 1.0
    var melee = 1.0
    var effect = 0.0
}

struct DelveEnemyStats: Codable, Equatable {
    let health: Double
    let rangeAttackPower: Double
    let meleeAttackPower: Double
    let effectAttackPower: Double
}

// These initial tunings reproduce docs/calibration/delve_reference.py. The
// reference character calibrates the floor; the player's actual equipment
// never feeds back into the stats of enemies already being faced.
struct DelveBalance: Codable, Equatable {
    var startingGearHealth = 50.0
    var startingGearShield = 50.0
    var startingGearAttack = 12.5
    var ordinaryStartSeconds = 2.0
    var ordinarySecondsPerDelve = 2.0 / 4999
    var bossStartSeconds = 30.0
    var bossSecondsPerDelve = 30.0 / 4999
    var startingGreenHits = 10.0
    var laterGreenHits = 5.0
    var greenHitMilestone = 1000.0
    var baseXPPerMinute = 50.0
    var xpDelveScale = 700.0
    var xpExponent = 2.5
    var baseEncounterBudget = 12.0
    var encounterBudgetExponent = 0.1
    var roomGroupingMultiplier = 0.25

    func validate() throws {
        let positives = [startingGearHealth, startingGearShield, startingGearAttack,
                         ordinaryStartSeconds, bossStartSeconds, startingGreenHits, laterGreenHits,
                         baseXPPerMinute, xpDelveScale, xpExponent, baseEncounterBudget]
        let nonnegative = [ordinarySecondsPerDelve, bossSecondsPerDelve,
                           encounterBudgetExponent, roomGroupingMultiplier]
        guard positives.allSatisfy({ $0.isFinite && $0 > 0 }),
              nonnegative.allSatisfy({ $0.isFinite && $0 >= 0 }),
              greenHitMilestone.isFinite, greenHitMilestone > 1,
              baseEncounterBudget >= 1 else { throw DelveError.invalidValue("balance") }
    }

    func itemStats(_ item: DelveLoot) throws -> DelveItemStats {
        try validate()
        let x = try DelveRules.scalingInput(item.power)
        let delta = 100 * (pow(1 + x / 4, 1.4) - pow(1 + x / 5, 1.2))
        var stats = DelveItemStats()
        switch item.kind {
        case .powerCore:
            stats.attackPower = startingGearAttack * 0.2 + delta / 32
            stats.health = startingGearHealth * 0.2 + delta / 8
            stats.shield = startingGearShield * 0.2 + delta / 8
            stats.defence = 2 + delta / 8
        case .armorCore:
            stats.health = startingGearHealth * 0.6 + delta / 2
            stats.defence = 1 + delta / 4
        case .pulsar:
            stats.attackPower = startingGearAttack * 0.6 + delta / 8
        case .specialPulsar:
            stats.attackSpeed = (x + 1) / 25
        case .shield:
            stats.shield = startingGearShield * 0.6 + delta / 2
            stats.shieldRegen = 5 * (pow(1 + x / 5, 1.2) - pow(1 + x / 5, 1.1))
        case .attachment:
            switch item.attachmentStat {
            case "AttackPower": stats.attackPower = startingGearAttack * 0.4 + delta / 40
            case "Health": stats.health = startingGearHealth * 0.4 + delta / 10
            case "Shield": stats.shield = startingGearShield * 0.4 + delta / 10
            case "Defence": stats.defence = 1 + delta / 10
            default: throw DelveError.invalidLoot
            }
        }
        stats = stats.scaled(by: item.rarity.statMultiplier)
        guard [stats.attackPower, stats.health, stats.shield, stats.defence, stats.attackSpeed, stats.shieldRegen]
            .allSatisfy({ $0.isFinite && $0 >= 0 }) else { throw DelveError.invalidValue("item stats") }
        return stats
    }

    func characterStats(level: Int, equipped: [DelveLoot], cap: Int = 100) throws -> DelveCharacterStats {
        guard level >= 1, cap >= 1 else { throw DelveError.invalidValue("character level") }
        var gear = DelveItemStats()
        for item in equipped { gear.add(try itemStats(item)) }
        return try combine(level: Double(min(level, cap)), gear: gear)
    }

    func referenceLevel(difficulty: Double) throws -> Double {
        try DelveRules.validateScore(difficulty)
        // Beyond the milestone: level 200 at Delve 20000, with no clamp.
        if difficulty >= 10000 { return difficulty / 100 }
        return Self.interpolate(difficulty, scores: DelveCalibration.referenceDelves,
                                values: DelveCalibration.referenceLevels)
    }

    func referenceRarityMultiplier(difficulty: Double) throws -> Double {
        try DelveRules.validateScore(difficulty)
        return Self.interpolate(min(difficulty, 10000), scores: [1, 1000, 2500, 5000, 10000],
                                values: DelveRarity.allCases.map(\.statMultiplier))
    }

    func referenceStats(difficulty: Double) throws -> DelveCharacterStats {
        // The average loadout is an ensemble over the four attachment types.
        // Individual legal loadouts can trade damage against capacity/armour.
        var gear = DelveItemStats()
        for kind in [DelveItemKind.powerCore, .armorCore, .pulsar, .specialPulsar, .shield] {
            gear.add(try itemStats(DelveLoot(kind: kind, power: difficulty, rarity: .common)))
        }
        for stat in ["AttackPower", "Health", "Shield", "Defence"] {
            gear.add(try itemStats(DelveLoot(kind: .attachment, power: difficulty, rarity: .common,
                                           attachmentStat: stat)).scaled(by: 0.5))
        }
        return try combine(level: referenceLevel(difficulty: difficulty),
                           gear: gear.scaled(by: referenceRarityMultiplier(difficulty: difficulty)))
    }

    func enemyStats(difficulty: Double, relative: DelveRelativeStats,
                    boss: Bool = false, elite: Bool = false) throws -> DelveEnemyStats {
        guard relative.health.isFinite, relative.health > 0,
              [relative.range, relative.melee, relative.effect].allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw DelveError.invalidValue("relative enemy stats")
        }
        let reference = try referenceStats(difficulty: difficulty)
        let target = boss ? bossSeconds(difficulty: difficulty) : ordinarySeconds(difficulty: difficulty)
        let hits = startingGreenHits + (laterGreenHits - startingGreenHits)
            * min((difficulty - 1) / (greenHitMilestone - 1), 1)
        let greenRaw = (reference.maxHealth + reference.maxShield) / hits + reference.flatArmour
        let x = try DelveRules.scalingInput(difficulty)
        // Retain the authored elite's four scaling-level offset continuously.
        let eliteFactor = elite ? pow(1 + (x + 4) / 4, 1.4) / pow(1 + x / 4, 1.4) : 1
        let result = DelveEnemyStats(health: reference.damagePerSecond * target * relative.health * eliteFactor,
                                    rangeAttackPower: greenRaw * relative.range * eliteFactor,
                                    meleeAttackPower: greenRaw * relative.melee * eliteFactor,
                                    effectAttackPower: greenRaw * relative.effect * eliteFactor)
        guard [result.health, result.rangeAttackPower, result.meleeAttackPower, result.effectAttackPower]
            .allSatisfy({ $0.isFinite && $0 >= 0 }) else { throw DelveError.invalidValue("enemy stats") }
        return result
    }

    func ordinarySeconds(difficulty: Double) -> Double { ordinaryStartSeconds + ordinarySecondsPerDelve * (difficulty - 1) }
    func bossSeconds(difficulty: Double) -> Double { bossStartSeconds + bossSecondsPerDelve * (difficulty - 1) }

    func referenceFloorSeconds(difficulty: Double) throws -> Double {
        try validate()
        let x = try DelveRules.scalingInput(difficulty)
        let budget = baseEncounterBudget * pow(1 + x, encounterBudgetExponent)
        // Canonical paired encounters, two seconds of room overhead, and 20%
        // combat allowance. Actual speed never multiplies an XP reward.
        return 1.2 * (budget / 1.25 * ordinarySeconds(difficulty: difficulty)
                      + 2 * budget / 2.5 + bossSeconds(difficulty: difficulty))
    }

    func floorXP(difficulty: Double) throws -> Double {
        let seconds = try referenceFloorSeconds(difficulty: difficulty)
        let xp = baseXPPerMinute * pow(1 + (difficulty - 1) / xpDelveScale, xpExponent) * seconds / 60
        guard xp.isFinite, xp > 0 else { throw DelveError.invalidValue("floor XP") }
        return xp
    }

    func xpAllocations(for plan: DelveFloorPlan) throws -> [UUID: Double] {
        try plan.validate()
        let pool = try floorXP(difficulty: plan.difficulty)
        let ordinaryWeight = plan.budget / 1.25 * ordinarySeconds(difficulty: plan.difficulty)
        let bossWeight = bossSeconds(difficulty: plan.difficulty)
        let ordinaryPool = pool * ordinaryWeight / (ordinaryWeight + bossWeight)
        let basePoints = plan.enemies.reduce(0) { $0 + $1.kind.points }
        var rewards = [UUID: Double]()
        for enemy in plan.enemies { rewards[enemy.id] = ordinaryPool * enemy.kind.points / basePoints }
        if let boss = plan.rooms.last { rewards[boss.id] = pool - ordinaryPool }
        // Only planned identities receive XP. Runtime summons are never added
        // to this table, and room count supplies no additional farming reward.
        return rewards
    }

    private func combine(level: Double, gear: DelveItemStats) throws -> DelveCharacterStats {
        try validate()
        let growth = (level + 4) / 5
        let stats = DelveCharacterStats(maxHealth: 100 * pow(growth, 1.2) + gear.health,
                                        maxShield: 100 * pow(growth, 1.1) + gear.shield,
                                        attackPower: 25 * pow(growth, 1.1) + gear.attackPower,
                                        flatArmour: gear.defence * 0.025,
                                        shotCooldown: max(0.05, 0.5 - 0.02 * gear.attackSpeed),
                                        shieldRegen: 0.3 * (growth + 0.1 * gear.shieldRegen))
        guard [stats.maxHealth, stats.maxShield, stats.attackPower, stats.flatArmour, stats.shotCooldown, stats.shieldRegen]
            .allSatisfy({ $0.isFinite && $0 >= 0 }) else { throw DelveError.invalidValue("character stats") }
        return stats
    }

    private static func interpolate(_ score: Double, scores: [Double], values: [Double]) -> Double {
        guard let upper = scores.firstIndex(where: { $0 > score }) else { return values.last! }
        let lower = max(0, upper - 1)
        let t = (score - scores[lower]) / (scores[upper] - scores[lower])
        return values[lower] + t * (values[upper] - values[lower])
    }
}
