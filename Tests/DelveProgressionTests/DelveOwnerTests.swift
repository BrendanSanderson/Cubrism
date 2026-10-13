import Foundation
import XCTest
@testable import CubrismProgression

final class DelveOwnerTests: XCTestCase {
    func testFreshAccountStartsWithOwnedCommonGearAndDerivedResources() throws {
        var account = try DelveProgression.freshAccount()
        XCTAssertEqual(account.experience.cap, 100)
        XCTAssertEqual(account.bankedItems.count, 7)
        XCTAssertEqual(account.equipped.count, 7)
        XCTAssertTrue(account.bankedItems.allSatisfy { $0.power == 1 && $0.rarity == .common })
        let stats = try account.characterStats()
        XCTAssertEqual(stats.maxHealth, 160)
        XCTAssertEqual(stats.maxShield, 140)
        XCTAssertEqual(stats.attackPower, 40)
        var random = SystemRandomNumberGenerator()
        try account.enterDungeon(using: &random)
        let resources = try XCTUnwrap(account.activeRun?.resources)
        XCTAssertEqual(resources.health, stats.maxHealth)
        XCTAssertEqual(resources.shield, stats.maxShield)
        XCTAssertEqual(account.activeRun?.bankedLoadout, account.equipped)
        try account.validateSnapshot()
    }

    func testOnlyPlannedKillsGiveXPAndGrowthAddsCapacityOnlyOnce() throws {
        let starter = try DelveProgression.freshAccount()
        var account = try DelveProgression(rating: 1000, levelUpCosts: [10, 20, 30],
                                           bankedItems: starter.bankedItems, equipped: starter.equipped)
        var random = SystemRandomNumberGenerator()
        let floor = try account.enterDungeon(using: &random)
        try account.receiveHit(floorID: floor, rawDamage: 100)
        let original = account
        XCTAssertFalse(try account.awardKill(floorID: floor, enemyID: UUID()))
        let bossID = try XCTUnwrap(account.activeRun?.floor.plan.rooms.last?.id)
        XCTAssertFalse(try account.awardKill(floorID: floor, enemyID: bossID), "Boss XP belongs to the atomic clear")
        XCTAssertEqual(account, original)
        let before = try XCTUnwrap(account.activeRun?.resources)
        let enemy = try XCTUnwrap(account.activeRun?.floor.plan.enemies.first)
        XCTAssertTrue(try account.awardKill(floorID: floor, enemyID: enemy.id))
        XCTAssertGreaterThan(account.experience.level, 1)
        let stats = try account.characterStats()
        let after = try XCTUnwrap(account.activeRun?.resources)
        XCTAssertEqual(after.health, min(stats.maxHealth, before.health + stats.maxHealth - before.peakHealth), accuracy: 1e-10)
        XCTAssertEqual(after.shield, min(stats.maxShield, before.shield + stats.maxShield - before.peakShield), accuracy: 1e-10)
        let credited = account
        XCTAssertFalse(try account.awardKill(floorID: floor, enemyID: enemy.id))
        XCTAssertEqual(account, credited)
        try account.validateSnapshot()
    }

    func testFinishCreditsBossOnceAndContinuationCarriesHealthWithoutRerollingPastLoot() throws {
        var account = try DelveProgression.freshAccount()
        var random = SystemRandomNumberGenerator()
        let floor = try account.enterDungeon(using: &random)
        let run = try XCTUnwrap(account.activeRun)
        let performance = try DelvePerformance(speed: 0.8, accuracy: 0.7, avoidance: 0.6)
        XCTAssertThrowsError(try account.finishFloor(floorID: floor, performance: performance, using: &random))
        XCTAssertEqual(account.activeRun, run)
        try account.receiveHit(floorID: floor, rawDamage: 180)
        for enemy in run.floor.plan.enemies { try account.awardKill(floorID: floor, enemyID: enemy.id) }
        XCTAssertTrue(try account.finishFloor(floorID: floor, performance: performance, using: &random))
        let checkpoint = try XCTUnwrap(account.activeRun)
        XCTAssertEqual(checkpoint.floor.phase, .checkpoint)
        XCTAssertEqual(checkpoint.loot.count, 2)
        XCTAssertTrue(checkpoint.loot.allSatisfy { $0.power == run.floor.difficulty })
        XCTAssertEqual(account.experience.lifetime, try account.rules.balance.floorXP(difficulty: run.floor.difficulty), accuracy: 1e-10)
        let completed = account
        XCTAssertFalse(try account.finishFloor(floorID: floor, performance: performance, using: &random))
        XCTAssertEqual(account, completed)
        let next = try account.continueRun(after: floor, using: &random)
        XCTAssertEqual(account.activeRun?.resources.health, checkpoint.resources.health)
        XCTAssertEqual(account.activeRun?.resources.shield, checkpoint.resources.maxShield)
        XCTAssertEqual(account.activeRun?.loot, checkpoint.loot)
        XCTAssertNotEqual(next, floor)
        XCTAssertThrowsError(try account.equipItem(checkpoint.loot[0].id, in: .shield))
        try account.validateSnapshot()
    }

    func testEquipmentUsesCalculatedStatsAndARepeatedCapacityDoesNotHeal() throws {
        var account = try DelveProgression.freshAccount()
        let originalArmor = try XCTUnwrap(account.equipped[.armorCore])
        var random = SystemRandomNumberGenerator()
        let floor = try account.enterDungeon(using: &random)
        try account.receiveHit(floorID: floor, rawDamage: 180)
        let difficulty = try XCTUnwrap(account.activeRun?.floor.difficulty)
        let better = try DelveLoot(kind: .armorCore, power: difficulty, rarity: .legendary)
        let second = try DelveLoot(kind: .shield, power: difficulty, rarity: .common)
        try account.clearFloor(floorID: floor, performance: DelvePerformance(speed: 0, accuracy: 0, avoidance: 0), loot: [better, second])
        try account.equipItem(better.id, in: .armorCore)
        let peak = try XCTUnwrap(account.activeRun?.resources)
        XCTAssertEqual(peak.maxHealth, try account.characterStats().maxHealth)
        try account.equipItem(originalArmor, in: .armorCore)
        let lowered = try XCTUnwrap(account.activeRun?.resources.health)
        try account.equipItem(better.id, in: .armorCore)
        XCTAssertEqual(account.activeRun?.resources.health, lowered)
        XCTAssertEqual(account.activeRun?.resources.peakHealth, peak.peakHealth)
        let nextFloor = try account.continueRun(after: floor, using: &random)
        try account.abandon(floorID: nextFloor)
        XCTAssertEqual(account.equipped[.armorCore], originalArmor)
        XCTAssertFalse(account.ownedItems.contains { $0.id == better.id })
        try account.equipItem(nil, in: .armorCore)
        XCTAssertNil(account.equipped[.armorCore])
        try account.equipItem(originalArmor, in: .armorCore)
        try account.validateSnapshot()
    }
}
