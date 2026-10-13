import Foundation
import XCTest
@testable import CubrismProgression

private struct FloorRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

final class DelveFloorTests: XCTestCase {
    func testEveryFloorHasReachableCombatAndOneFinalBossWithoutShortcuts() throws {
        for score in [1.0, 11, 21, 31, 101, 854, 2500, 10000, 20000, 100000] {
            for seed in 0..<50 {
                var random = FloorRandom(state: UInt64(seed))
                let plan = try DelveFloorPlanner().generate(difficulty: score, using: &random)
                try plan.validate()
                var visited = Set<UUID>()
                var current = try XCTUnwrap(plan.rooms.first)
                while true {
                    visited.insert(current.id)
                    let next = plan.doors(for: current.id).compactMap { door in
                        plan.rooms.first { $0.position == door.destination && !visited.contains($0.id) }
                    }
                    if next.isEmpty { break }
                    XCTAssertEqual(next.count, 1)
                    current = next[0]
                }
                XCTAssertEqual(visited.count, plan.rooms.count)
                guard case .boss = current.encounter else { return XCTFail("Route must end at the boss") }
                XCTAssertFalse(plan.combatRooms.isEmpty)
                XCTAssertTrue(plan.enemies.allSatisfy { $0.kind.minimumDifficulty <= score })
                XCTAssertLessThanOrEqual(plan.spentPoints, plan.budget + 1e-9)
                XCTAssertLessThan(plan.budget - plan.spentPoints, 1 + 1e-9)
            }
        }
    }

    func testSparseFloorsBuyMoreEnemiesAndRoomsAtTheSameEarlyBudget() throws {
        var random = FloorRandom(state: 25)
        let sparse = try DelveFloorPlanner().generate(difficulty: 1, density: .sparse, using: &random)
        let balanced = try DelveFloorPlanner().generate(difficulty: 1, density: .balanced, using: &random)
        let dense = try DelveFloorPlanner().generate(difficulty: 1, density: .dense, using: &random)
        XCTAssertEqual(sparse.budget, dense.budget)
        XCTAssertGreaterThan(sparse.enemies.count, balanced.enemies.count)
        XCTAssertGreaterThan(balanced.enemies.count, dense.enemies.count)
        XCTAssertGreaterThan(sparse.combatRooms.count, balanced.combatRooms.count)
        XCTAssertGreaterThan(balanced.combatRooms.count, dense.combatRooms.count)
    }

    func testNewEnemiesBecomeEligibleQuicklyButAreNotGuaranteed() throws {
        for index in DelveEnemyKind.allCases.indices {
            let threshold = Double(index * 10 + 1)
            XCTAssertEqual(DelveEnemyKind.allCases.filter { $0.minimumDifficulty <= threshold }.count, index + 1)
        }
        var random = FloorRandom(state: 99)
        var foundNewEnemy = false
        var foundFloorWithoutNewEnemy = false
        for _ in 0..<1000 {
            let plan = try DelveFloorPlanner().generate(difficulty: 11, density: .dense, using: &random)
            if plan.enemies.contains(where: { $0.kind == .melee }) { foundNewEnemy = true }
            else { foundFloorWithoutNewEnemy = true }
        }
        XCTAssertTrue(foundNewEnemy)
        XCTAssertTrue(foundFloorWithoutNewEnemy)
    }

    func testStoredFloorPreservesEveryRoomEnemySpawnAndBossAcrossReloadAndContinuation() throws {
        var random = FloorRandom(state: 102)
        var account = try DelveProgression(rating: 20000, levelUpCosts: [100])
        let id = try account.startRun(maxHealth: 100, maxShield: 100, using: &random)
        let original = try XCTUnwrap(account.activeRun?.floor.plan)
        let data = try JSONEncoder().encode(account)
        account = try JSONDecoder().decode(DelveProgression.self, from: data)
        try account.validateSnapshot()
        XCTAssertEqual(account.activeRun?.floor.plan, original)
        XCTAssertEqual(account.activeRun?.floor.difficulty, original.difficulty)
        let rewards = try DelveRules.rollRewards(difficulty: original.difficulty, depth: 1, using: &random)
            .map { try DelveLoot(kind: .shield, power: $0.power, rarity: $0.rarity) }
        try account.clearFloor(floorID: id, performance: DelvePerformance(speed: 0, accuracy: 0, avoidance: 0), loot: rewards)
        XCTAssertEqual(account.activeRun?.floor.plan, original)
        try account.continueRun(after: id, using: &random)
        let next = try XCTUnwrap(account.activeRun?.floor.plan)
        XCTAssertNotEqual(next.rooms.map(\.id), original.rooms.map(\.id))
        XCTAssertEqual(next.difficulty, account.activeRun?.floor.difficulty)
        XCTAssertGreaterThan(next.budget, try DelveFloorPlanner().generate(difficulty: 10000, using: &random).budget)
    }

    func testCorruptRouteEncountersAndPowerAreRejected() throws {
        var random = FloorRandom(state: 4)
        let plan = try DelveFloorPlanner().generate(difficulty: 1, using: &random)
        let encoded = try JSONEncoder().encode(plan)
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        for corruption in 0..<5 {
            var document = original
            var rooms = try XCTUnwrap(document["rooms"] as? [[String: Any]])
            switch corruption {
            case 0: rooms[1]["position"] = ["x": 999, "y": 999]
            case 1: rooms[1]["id"] = rooms[0]["id"]
            case 2: rooms[rooms.count - 1]["encounter"] = ["start": [:]]
            case 3:
                var encounter = try XCTUnwrap(rooms[1]["encounter"] as? [String: Any])
                var combat = try XCTUnwrap(encounter["combat"] as? [String: Any])
                var enemies = try XCTUnwrap(combat["_0"] as? [[String: Any]])
                enemies[0]["id"] = rooms[rooms.count - 1]["id"]
                combat["_0"] = enemies
                encounter["combat"] = combat
                rooms[1]["encounter"] = encounter
            default: document["budget"] = 1
            }
            document["rooms"] = rooms
            let invalid = try JSONDecoder().decode(DelveFloorPlan.self, from: JSONSerialization.data(withJSONObject: document))
            XCTAssertThrowsError(try invalid.validate())
        }
        XCTAssertThrowsError(try DelveFloorPlanner().generate(difficulty: 0, using: &random))
        var badTuning = DelveFloorPlanner()
        badTuning.groupingMultiplier = -1
        XCTAssertThrowsError(try badTuning.generate(difficulty: 1, using: &random))
    }
}
