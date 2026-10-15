import Foundation
import XCTest
@testable import CubrismProgression

private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

final class DelveProgressionTests: XCTestCase {
    func testLootRemembersEveryFloorAfterContinueReloadAndExtraction() throws {
        var state = try account()
        var random = SeededRandom(state: 345)
        var floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        var expected = [UUID: Int]()
        for depth in 1...3 {
            let drops = try rewards(state, using: &random)
            try state.clearFloor(floorID: floor, performance: performance(), loot: drops)
            for item in drops { expected[item.id] = depth }
            state = try restore(state)
            try state.validateSnapshot()
            for item in try XCTUnwrap(state.activeRun).loot {
                XCTAssertEqual(item.floorDepth, expected[item.id])
            }
            if depth < 3 { floor = try state.continueRun(after: floor, using: &random) }
        }
        try state.extract(runID: XCTUnwrap(state.activeRun).id)
        state = try restore(state)
        XCTAssertEqual(state.bankedItems.count, expected.count)
        for item in state.bankedItems { XCTAssertEqual(item.floorDepth, expected[item.id]) }
        XCTAssertThrowsError(try DelveLoot(kind: .pulsar, power: 1, rarity: .common, floorDepth: 0))
        let oldItem = try DelveLoot(kind: .pulsar, power: 1, rarity: .common)
        let encoded = try JSONEncoder().encode(oldItem)
        XCTAssertNil(try JSONDecoder().decode(DelveLoot.self, from: encoded).floorDepth)
    }

    private func performance(_ value: Double = 0) throws -> DelvePerformance {
        try DelvePerformance(speed: value, accuracy: value, avoidance: value)
    }

    private func account(rating: Double = 2500) throws -> DelveProgression {
        try DelveProgression(rating: rating, levelUpCosts: Array(repeating: 100, count: 99))
    }

    private func rewards(_ state: DelveProgression, using random: inout SeededRandom) throws -> [DelveLoot] {
        let run = try XCTUnwrap(state.activeRun)
        return try DelveRules.rollRewards(difficulty: run.floor.difficulty, depth: run.depth, using: &random)
            .map { try DelveLoot(kind: .armorCore, power: $0.power, rarity: $0.rarity) }
    }

    private func restore(_ state: DelveProgression) throws -> DelveProgression {
        try JSONDecoder().decode(DelveProgression.self, from: JSONEncoder().encode(state))
    }

    func testAcceptedRarityEndpointsAndUncappedBestOfDepth() throws {
        for (difficulty, expected) in [(1.0, [0.49, 0.30, 0.15, 0.05, 0.01]),
                                        (10000.0, [0.05, 0.375, 0.375, 0.15, 0.05]),
                                        (100000.0, [0.05, 0.375, 0.375, 0.15, 0.05])] {
            let actual = try DelveRules.rarityProbabilities(difficulty: difficulty)
            for (a, e) in zip(actual, expected) { XCTAssertEqual(a, e, accuracy: 1e-12) }
        }
        for difficulty in stride(from: 1.0, through: 10001, by: 100) {
            for depth in [1, 2, 6, 10, 1000] {
                let odds = try DelveRules.rarityProbabilities(difficulty: difficulty, depth: depth)
                XCTAssertTrue(odds.allSatisfy { $0 >= 0 && $0 <= 1 })
                XCTAssertEqual(odds.reduce(0, +), 1, accuracy: 1e-12)
            }
        }
        let ten = try DelveRules.rarityProbabilities(difficulty: 10000, depth: 10)
        XCTAssertEqual(ten[4], 1 - pow(0.95, 10), accuracy: 1e-12)
        XCTAssertGreaterThan(try DelveRules.rarityProbabilities(difficulty: 10000, depth: 20)[4], ten[4])
    }

    func testRatingCrossoversPerformanceAndSampledChallenge() throws {
        let rules = DelveRules()
        XCTAssertEqual(try rules.winGain(entryRating: 2500, difficulty: 2500, depth: 1,
                                         performance: performance()), 10)
        XCTAssertEqual(try rules.loss(entryRating: 2500, difficulty: 2500), 10)
        XCTAssertEqual(try rules.loss(entryRating: 10000, difficulty: 10000), 20)
        XCTAssertEqual(try rules.winGain(entryRating: 2500, difficulty: 2500, depth: 6,
                                         performance: performance(1)), 16.5)
        XCTAssertGreaterThan(try rules.winGain(entryRating: 854, difficulty: 900, depth: 1,
                                               performance: performance()), 10)
        XCTAssertLessThan(try rules.loss(entryRating: 854, difficulty: 900),
                          try rules.loss(entryRating: 854, difficulty: 854))
        XCTAssertEqual(try DelvePerformance(speed: 1, accuracy: 0, avoidance: 0).score, 0.4)
        XCTAssertEqual(try DelvePerformance(speed: 0, accuracy: 0, avoidance: 1).score, 0.2)
        XCTAssertEqual(try DelveRules.scalingInput(854), 8.53)
        XCTAssertGreaterThan(try DelveRules.scalingInput(20000), 100)
    }

    func testGaussianSamplingHasExpectedSpreadAndRedrawsAtMinimum() throws {
        let rules = DelveRules()
        var random = SeededRandom(state: 143)
        let samples = try (0..<20000).map { _ in try rules.sampleDifficulty(rating: 20000, using: &random) }
        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.reduce(0) { $0 + pow($1 - mean, 2) } / Double(samples.count)
        XCTAssertEqual(mean, 20000, accuracy: 30)
        XCTAssertEqual(sqrt(variance), 1000, accuracy: 30)
        for _ in 0..<1000 {
            XCTAssertGreaterThanOrEqual(try rules.sampleDifficulty(rating: 1, using: &random), 1)
        }
    }

    func testRewardCountAndPowerUseCurrentFloorAndDepth() throws {
        var random = SeededRandom(state: 17)
        for _ in 0..<100 {
            XCTAssertEqual(try DelveRules.rollRewards(difficulty: 20000, depth: 1, using: &random).count, 2)
            let deep = try DelveRules.rollRewards(difficulty: 20000, depth: 10, using: &random)
            XCTAssertEqual(deep.count, 3)
            XCTAssertTrue(deep.allSatisfy { $0.power == 20000 })
        }
    }

    func testDeathOnFourthFloorKeepsAllXPAndPriorRatingGainsButLosesEveryRunItem() throws {
        var state = try account()
        var random = SeededRandom(state: 1)
        var floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        for _ in 0..<3 {
            try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: 100)
            let loot = try rewards(state, using: &random)
            try state.clearFloor(floorID: floor, performance: performance(), loot: loot)
            floor = try state.continueRun(after: floor, using: &random)
        }
        try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: 100)
        let run = try XCTUnwrap(state.activeRun)
        XCTAssertGreaterThanOrEqual(run.loot.count, 6)
        let expectedRating = state.rating - (try state.rules.loss(entryRating: run.floor.entryRating,
                                                                 difficulty: run.floor.difficulty))
        try state.takeDamage(floorID: floor, amount: 200)
        XCTAssertNil(state.activeRun)
        XCTAssertEqual(state.bankedItems.count, 0)
        XCTAssertEqual(state.experience.lifetime, 460, accuracy: 1e-9)
        XCTAssertEqual(state.rating, expectedRating)
        XCTAssertEqual(state.lastSettlement?.outcome, .died)
        let ended = state
        XCTAssertThrowsError(try state.takeDamage(floorID: floor, amount: 200))
        XCTAssertEqual(state, ended)
    }

    func testExtractionAfterMultipleFloorsBanksLootOnceAndNewRunResetsBonuses() throws {
        var state = try account()
        var random = SeededRandom(state: 2)
        var floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        for depth in 1...6 {
            let loot = try rewards(state, using: &random)
            try state.clearFloor(floorID: floor, performance: performance(), loot: loot)
            if depth < 6 { floor = try state.continueRun(after: floor, using: &random) }
        }
        let run = try XCTUnwrap(state.activeRun)
        let allLoot = run.loot
        try state.extract(runID: run.id)
        state = try restore(state)
        XCTAssertFalse(try state.extract(runID: run.id))
        XCTAssertEqual(state.bankedItems, allLoot)
        floor = try state.startRun(maxHealth: 150, maxShield: 130, using: &random)
        XCTAssertEqual(state.activeRun?.depth, 1)
        XCTAssertEqual(state.activeRun?.resources.health, 150)
        XCTAssertEqual(state.activeRun?.resources.shield, 130)
        XCTAssertEqual(try rewards(state, using: &random).count, 2)
        let xp = state.experience.lifetime
        try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: 10)
        XCTAssertEqual(state.experience.lifetime - xp, 10)
    }

    func testSaveRoundTripCannotRepeatXPOrClearOrRefillShield() throws {
        var state = try account()
        var random = SeededRandom(state: 3)
        let floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        let event = UUID()
        try state.takeDamage(floorID: floor, amount: 120)
        try state.awardXP(floorID: floor, eventID: event, baseAmount: 10)
        let combat = state
        state = try restore(state)
        XCTAssertEqual(state, combat)
        XCTAssertFalse(try state.awardXP(floorID: floor, eventID: event, baseAmount: 999))
        let loot = try rewards(state, using: &random)
        try state.clearFloor(floorID: floor, performance: performance(), loot: loot)
        let checkpoint = state
        state = try restore(state)
        XCTAssertFalse(try state.clearFloor(floorID: floor, performance: performance(1), loot: loot))
        XCTAssertEqual(state, checkpoint)
        let next = try state.continueRun(after: floor, using: &random)
        XCTAssertEqual(state.activeRun?.resources.health, 80)
        XCTAssertEqual(state.activeRun?.resources.shield, 100)
        XCTAssertEqual(state.activeRun?.floor.entryRating, checkpoint.rating)
        try state.takeDamage(floorID: next, amount: 50)
        let injured = state
        state = try restore(state)
        XCTAssertThrowsError(try state.continueRun(after: floor, using: &random))
        XCTAssertEqual(state, injured)
        XCTAssertEqual(state.activeRun?.resources.shield, 50)
    }

    func testEquippedRunLootIsLostAndBankedLoadoutSurvivesFailure() throws {
        let old = try DelveLoot(kind: .armorCore, power: 1, rarity: .common)
        var state = try DelveProgression(levelUpCosts: [100], bankedItems: [old], equipped: [.armorCore: old.id])
        var random = SeededRandom(state: 4)
        let floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        let loot = try rewards(state, using: &random)
        try state.clearFloor(floorID: floor, performance: performance(), loot: loot)
        try state.equip(loot[0].id, in: .armorCore, maxHealth: 150, maxShield: 100)
        XCTAssertEqual(state.equipped[.armorCore], loot[0].id)
        XCTAssertEqual(state.bankedItems, [old])
        state = try restore(state)
        let next = try state.continueRun(after: floor, using: &random)
        try state.abandon(floorID: next)
        XCTAssertEqual(state.bankedItems, [old])
        XCTAssertEqual(state.equipped[.armorCore], old.id)
        XCTAssertEqual(state.lastSettlement?.outcome, .abandoned)
    }

    func testPeakCapacityPreventsRepeatedSwapHealingAcrossSaveAndFloorBoundaries() throws {
        var state = try account()
        var random = SeededRandom(state: 5)
        let floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        try state.takeDamage(floorID: floor, amount: 170)
        try state.changeCapacity(floorID: floor, maxHealth: 150, maxShield: 150)
        XCTAssertEqual(state.activeRun?.resources.health, 80)
        XCTAssertEqual(state.activeRun?.resources.shield, 50)
        try state.changeCapacity(floorID: floor, maxHealth: 100, maxShield: 100)
        state = try restore(state)
        try state.changeCapacity(floorID: floor, maxHealth: 150, maxShield: 150)
        XCTAssertEqual(state.activeRun?.resources.health, 80)
        XCTAssertEqual(state.activeRun?.resources.shield, 50)
        try state.changeCapacity(floorID: floor, maxHealth: 175, maxShield: 175)
        XCTAssertEqual(state.activeRun?.resources.health, 105)
        let loot = try rewards(state, using: &random)
        try state.clearFloor(floorID: floor, performance: performance(), loot: loot)
        try state.continueRun(after: floor, using: &random)
        XCTAssertEqual(state.activeRun?.resources.health, 105)
        XCTAssertEqual(state.activeRun?.resources.shield, 175)
        XCTAssertEqual(state.activeRun?.resources.peakHealth, 175)
    }

    func testCharacterCapDiscardsProgressOverflowButRetainsLifetimeXP() throws {
        var state = try account()
        var random = SeededRandom(state: 6)
        let floor = try state.startRun(maxHealth: 100, maxShield: 100, using: &random)
        try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: 10000)
        XCTAssertEqual(state.experience.level, 100)
        XCTAssertEqual(state.experience.progress, 0)
        try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: 123)
        state = try restore(state)
        try state.abandon(floorID: floor)
        XCTAssertEqual(state.experience.level, 100)
        XCTAssertEqual(state.experience.progress, 0)
        XCTAssertEqual(state.experience.lifetime, 10123)
    }

    func testInvalidInputsAndTransitionsDoNotPartiallyChangeState() throws {
        XCTAssertThrowsError(try DelveRules.rarityProbabilities(difficulty: .nan))
        XCTAssertThrowsError(try DelveRules.continuationBonus(depth: 0))
        XCTAssertThrowsError(try DelvePerformance(speed: 2, accuracy: 1, avoidance: 1))
        var state = try account(rating: 1)
        var random = SeededRandom(state: 7)
        let floor = try state.startRun(maxHealth: 100, maxShield: 0, using: &random)
        let original = state
        XCTAssertThrowsError(try state.startRun(maxHealth: 100, maxShield: 0, using: &random))
        XCTAssertThrowsError(try state.continueRun(after: floor, using: &random))
        XCTAssertThrowsError(try state.extract(runID: XCTUnwrap(state.activeRun).id))
        XCTAssertThrowsError(try state.awardXP(floorID: floor, eventID: UUID(), baseAmount: .infinity))
        XCTAssertThrowsError(try state.clearFloor(floorID: floor, performance: performance(), loot: []))
        XCTAssertThrowsError(try state.changeCapacity(floorID: floor, maxHealth: -1, maxShield: 0))
        XCTAssertEqual(state, original)
        try state.abandon(floorID: floor)
        XCTAssertEqual(state.rating, 1)
    }
}
