import Foundation
import XCTest
@testable import CubrismProgression

final class DelveBalanceTests: XCTestCase {
    private let balance = DelveBalance()

    private func loadout(power: Double, rarity: DelveRarity, first: String, second: String) throws -> [DelveLoot] {
        var items = try [DelveItemKind.powerCore, .armorCore, .pulsar, .specialPulsar, .shield]
            .map { try DelveLoot(kind: $0, power: power, rarity: rarity) }
        for stat in [first, second] {
            items.append(try DelveLoot(kind: .attachment, power: power, rarity: rarity, attachmentStat: stat))
        }
        return items
    }

    private func averageCharacter(power: Double, rarity: DelveRarity, level: Int) throws -> DelveCharacterStats {
        var hp = 0.0, shield = 0.0, attack = 0.0, armour = 0.0, cooldown = 0.0, regen = 0.0
        for first in ["AttackPower", "Health", "Shield", "Defence"] {
            for second in ["AttackPower", "Health", "Shield", "Defence"] {
                let stats = try balance.characterStats(level: level,
                                                       equipped: loadout(power: power, rarity: rarity, first: first, second: second))
                hp += stats.maxHealth / 16
                shield += stats.maxShield / 16
                attack += stats.attackPower / 16
                armour += stats.flatArmour / 16
                cooldown += stats.shotCooldown / 16
                regen += stats.shieldRegen / 16
            }
        }
        return DelveCharacterStats(maxHealth: hp, maxShield: shield, attackPower: attack,
                                    flatArmour: armour, shotCooldown: cooldown, shieldRegen: regen)
    }

    func testAcceptedKillTimeSurvivalAndReferenceRarityAnchors() throws {
        for (score, ordinary, boss, hits, rarity) in [(1.0, 2.0, 30.0, 10.0, 1.0),
                                                      (1000, 2.3996799359871974, 35.99519903980796, 5, 1.25),
                                                      (2500, 2.999799959991998, 44.99699939987998, 5, 1.5),
                                                      (5000, 4, 60, 5, 2),
                                                      (10000, 6.000400080016003, 90.00600120024005, 5, 2.5)] {
            let hero = try balance.referenceStats(difficulty: score)
            let green = try balance.enemyStats(difficulty: score, relative: DelveRelativeStats(melee: 0.5))
            let finalBoss = try balance.enemyStats(difficulty: score, relative: DelveRelativeStats(), boss: true)
            XCTAssertEqual(green.health / hero.damagePerSecond, ordinary, accuracy: 1e-10)
            XCTAssertEqual(finalBoss.health / hero.damagePerSecond, boss, accuracy: 1e-10)
            XCTAssertEqual((hero.maxHealth + hero.maxShield) / (green.rangeAttackPower - hero.flatArmour), hits, accuracy: 1e-10)
            XCTAssertEqual(try balance.referenceRarityMultiplier(difficulty: score), rarity, accuracy: 1e-12)
        }
    }

    func testStartingGearIsOneThirdOfAverageCapacityAndAttackAndWholeRarityMatters() throws {
        let common = try averageCharacter(power: 1, rarity: .common, level: 1)
        let rare = try averageCharacter(power: 1, rarity: .rare, level: 1)
        XCTAssertEqual(common.maxHealth, 150, accuracy: 1e-12)
        XCTAssertEqual(common.maxShield, 150, accuracy: 1e-12)
        XCTAssertEqual(common.attackPower, 37.5, accuracy: 1e-12)
        XCTAssertEqual((common.maxHealth - 100) / common.maxHealth, 1.0 / 3, accuracy: 1e-12)
        XCTAssertEqual((common.attackPower - 25) / common.attackPower, 1.0 / 3, accuracy: 1e-12)
        XCTAssertEqual(rare.maxHealth, 175, accuracy: 1e-12)
        XCTAssertEqual(rare.maxShield, 175, accuracy: 1e-12)
        XCTAssertEqual(rare.damagePerSecond / common.damagePerSecond - 1, 0.167602245389, accuracy: 1e-10)
        for kind in [DelveItemKind.powerCore, .armorCore, .pulsar, .specialPulsar, .shield, .attachment] {
            let stat = kind == .attachment ? "Defence" : nil
            let c = try balance.itemStats(DelveLoot(kind: kind, power: 854, rarity: .common, attachmentStat: stat))
            let l = try balance.itemStats(DelveLoot(kind: kind, power: 854, rarity: .legendary, attachmentStat: stat))
            XCTAssertEqual(l, c.scaled(by: 2.5))
        }
    }

    func testFractionalPowerAndReferenceStatsAreContinuousAcrossLegacyLevelBoundaries() throws {
        for score in [100.0, 1000, 2500, 5000, 10000] {
            let lower = try balance.itemStats(DelveLoot(kind: .armorCore, power: score - 0.001, rarity: .epic))
            let upper = try balance.itemStats(DelveLoot(kind: .armorCore, power: score + 0.001, rarity: .epic))
            XCTAssertGreaterThan(upper.health, lower.health)
            XCTAssertLessThan(upper.health / lower.health - 1, 0.0001)
            let a = try balance.referenceStats(difficulty: score - 0.001)
            let b = try balance.referenceStats(difficulty: score + 0.001)
            XCTAssertLessThan(abs(b.damagePerSecond / a.damagePerSecond - 1), 0.0001)
        }
        let green = try balance.enemyStats(difficulty: 854, relative: DelveRelativeStats())
        let heavy = try balance.enemyStats(difficulty: 854,
                                          relative: DelveRelativeStats(health: 1.5, range: 4, melee: 2, effect: 0.4))
        XCTAssertEqual(heavy.health / green.health, 1.5, accuracy: 1e-12)
        XCTAssertEqual(heavy.rangeAttackPower / green.rangeAttackPower, 4, accuracy: 1e-12)
        XCTAssertEqual(heavy.effectAttackPower / green.rangeAttackPower, 0.4, accuracy: 1e-12)
    }

    func testUncappedGearAndEnemiesUseVirtualReferenceLevelsAfterTheCharacterCap() throws {
        for (score, level) in [(20000.0, 200.0), (50000, 500), (100000, 1000)] {
            XCTAssertEqual(try balance.referenceLevel(difficulty: score), level)
            let reference = try balance.referenceStats(difficulty: score)
            let actual = try averageCharacter(power: score, rarity: .legendary, level: 100)
            let enemy = try balance.enemyStats(difficulty: score, relative: DelveRelativeStats())
            XCTAssertLessThan(actual.damagePerSecond, reference.damagePerSecond)
            XCTAssertGreaterThan(enemy.health / actual.damagePerSecond, balance.ordinarySeconds(difficulty: score))
            XCTAssertLessThan((actual.maxHealth + actual.maxShield) / (enemy.rangeAttackPower - actual.flatArmour), 5)
        }
        let a = try balance.itemStats(DelveLoot(kind: .armorCore, power: 10000, rarity: .legendary))
        let b = try balance.itemStats(DelveLoot(kind: .armorCore, power: 20000, rarity: .legendary))
        XCTAssertGreaterThan(b.health, a.health)
        let gear = try loadout(power: 20000, rarity: .legendary, first: "Health", second: "Shield")
        XCTAssertEqual(try balance.characterStats(level: 200, equipped: gear), try balance.characterStats(level: 100, equipped: gear))
    }

    func testEquivalentBudgetLayoutsHaveTheSameXPAndOnlyPlannedKillsAreRewarded() throws {
        var random = SystemRandomNumberGenerator()
        for score in [1.0, 2500, 10000, 20000] {
            let pool = try balance.floorXP(difficulty: score)
            for density in DelveDensity.allCases {
                let plan = try DelveFloorPlanner().generate(difficulty: score, density: density, using: &random)
                let rewards = try balance.xpAllocations(for: plan)
                XCTAssertEqual(rewards.values.reduce(0, +), pool, accuracy: pool * 1e-12)
                XCTAssertEqual(rewards.count, plan.enemies.count + 1)
                XCTAssertNil(rewards[UUID()], "Unplanned summons have no XP allocation")
                XCTAssertGreaterThan(rewards[try XCTUnwrap(plan.rooms.last).id] ?? 0, 0)
            }
        }
        XCTAssertGreaterThan(try balance.floorXP(difficulty: 10000), try balance.floorXP(difficulty: 1000))
        XCTAssertGreaterThan(try balance.floorXP(difficulty: 20000), try balance.floorXP(difficulty: 10000))
    }

    func testFixedXPCostsMatchThePacingStudyAndDiscardAllCapOverflow() throws {
        let costs = DelveCalibration.levelUpCosts
        XCTAssertEqual(costs.count, 99)
        XCTAssertTrue(zip(costs, costs.dropFirst()).allSatisfy { $0 < $1 })
        for (level, expected) in [(1, 103.3), (10, 1373.1), (25, 9801.5), (50, 59609.2), (99, 358454.2)] {
            XCTAssertEqual(costs[level - 1], expected, accuracy: 0.1)
        }
        var xp = try DelveExperience(levelUpCosts: costs)
        let total = costs.reduce(0, +)
        try xp.award(total + 1000)
        XCTAssertEqual(xp.level, 100)
        XCTAssertEqual(xp.progress, 0)
        try xp.award(1000)
        XCTAssertEqual(xp.progress, 0)
        XCTAssertEqual(xp.lifetime, total + 2000, accuracy: 1e-8)
        let referenceMinutes = (1..<100).reduce(0.0) { $0 + 2 + 2 * sqrt(Double($1 - 1)) }
        XCTAssertEqual(referenceMinutes, 1501.026145, accuracy: 1e-6)
    }

    func testInvalidTuningAndRelativeStatsFailBeforeGeneratingStats() throws {
        var invalid = balance
        invalid.laterGreenHits = 0
        XCTAssertThrowsError(try invalid.referenceStats(difficulty: 5000))
        invalid = balance
        invalid.baseEncounterBudget = 0.5
        XCTAssertThrowsError(try invalid.floorXP(difficulty: 1))
        XCTAssertThrowsError(try balance.enemyStats(difficulty: 1, relative: DelveRelativeStats(health: -1)))
        XCTAssertThrowsError(try balance.characterStats(level: 0, equipped: []))
        XCTAssertThrowsError(try balance.referenceStats(difficulty: .infinity))
    }
}
