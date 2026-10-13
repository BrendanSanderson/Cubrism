import Foundation
import XCTest
@testable import CubrismProgression

private struct SaveRandom: RandomNumberGenerator {
    var state: UInt64 = 71
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

private func saveTestDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func saveTestAccount() throws -> DelveProgression {
    let item = try DelveLoot(kind: .armorCore, power: 1, rarity: .common)
    return try DelveProgression(rating: 2500, levelUpCosts: Array(repeating: 100, count: 99),
                                bankedItems: [item], equipped: [.armorCore: item.id])
}

@MainActor
private func saveTestStore(_ file: URL) throws -> DelveSaveStore {
    try DelveSaveStore(fileURL: file, makeNewAccount: saveTestAccount)
}

private func saveTestLoot(_ state: DelveProgression, using random: inout SaveRandom) throws -> [DelveLoot] {
    let run = try XCTUnwrap(state.activeRun)
    return try DelveRules.rollRewards(difficulty: run.floor.difficulty, depth: run.depth, using: &random)
        .map { try DelveLoot(kind: .armorCore, power: $0.power, rarity: $0.rarity) }
}

private func replaceJSONValue(_ value: Any, at path: ArraySlice<String>, in object: inout [String: Any]) {
    let key = path.first!
    if path.count == 1 {
        object[key] = value
    } else {
        var child = object[key] as! [String: Any]
        replaceJSONValue(value, at: path.dropFirst(), in: &child)
        object[key] = child
    }
}

final class DelveSaveTests: XCTestCase {
    func testFreshAccountIsPersistedAndRestoringNeverCallsInitializer() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("nested/delve.json")
            let store = try saveTestStore(file)
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
            let restored = try DelveSaveStore(fileURL: file) {
                XCTFail("An existing save must not initialize a new account")
                return try saveTestAccount()
            }
            XCTAssertEqual(restored.progression, store.progression)
        }
    }

    func testCombatReloadPreservesDifficultyXPEventsAndCapacityHistory() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            let floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let event = UUID()
            try store.transaction {
                try $0.takeDamage(floorID: floor, amount: 170)
                try $0.awardXP(floorID: floor, eventID: event, baseAmount: 123)
                try $0.changeCapacity(floorID: floor, maxHealth: 150, maxShield: 150)
                try $0.changeCapacity(floorID: floor, maxHealth: 100, maxShield: 100)
            }
            let restored = try saveTestStore(file)
            XCTAssertEqual(restored.progression, store.progression)
            let previous = try Data(contentsOf: file)
            XCTAssertFalse(try restored.transaction { try $0.awardXP(floorID: floor, eventID: event, baseAmount: 999) })
            XCTAssertEqual(try Data(contentsOf: file), previous)
            try restored.transaction { try $0.changeCapacity(floorID: floor, maxHealth: 150, maxShield: 150) }
            XCTAssertEqual(restored.progression.activeRun?.resources.health, 80)
            XCTAssertEqual(restored.progression.activeRun?.resources.shield, 50)
            XCTAssertEqual(restored.progression.activeRun?.floor.difficulty, store.progression.activeRun?.floor.difficulty)
            XCTAssertEqual(restored.progression.experience.lifetime, 123)
        }
    }

    func testCheckpointEquipmentAndContinuationSurviveReloadWithoutExtraRefill() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            let floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            try store.transaction { try $0.takeDamage(floorID: floor, amount: 170) }
            let loot = try saveTestLoot(store.progression, using: &random)
            let performance = try DelvePerformance(speed: 0.6, accuracy: 0.7, avoidance: 0.4)
            try store.transaction {
                try $0.awardXP(floorID: floor, eventID: UUID(), baseAmount: 50)
                try $0.clearFloor(floorID: floor, performance: performance, loot: loot)
                try $0.equip(loot[0].id, in: .armorCore, maxHealth: 150, maxShield: 150)
            }
            let checkpoint = try saveTestStore(file)
            XCTAssertEqual(checkpoint.progression, store.progression)
            XCTAssertFalse(try checkpoint.transaction { try $0.clearFloor(floorID: floor, performance: performance, loot: loot) })
            let next = try checkpoint.transaction { try $0.continueRun(after: floor, using: &random) }
            XCTAssertEqual(checkpoint.progression.activeRun?.resources.health, 80)
            XCTAssertEqual(checkpoint.progression.activeRun?.resources.shield, 150)
            try checkpoint.transaction { try $0.takeDamage(floorID: next, amount: 20) }
            let resumed = try saveTestStore(file)
            XCTAssertEqual(resumed.progression, checkpoint.progression)
            XCTAssertEqual(resumed.progression.activeRun?.resources.shield, 130)
            XCTAssertEqual(resumed.progression.activeRun?.depth, 2)
            XCTAssertThrowsError(try resumed.transaction { try $0.continueRun(after: floor, using: &random) })
            XCTAssertEqual(resumed.progression.activeRun?.resources.shield, 130)
        }
    }

    func testFourthFloorDeathPersistsXPRatingAndRestoredBankedEquipment() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            let original = store.progression
            var random = SaveRandom()
            var floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let performance = try DelvePerformance(speed: 0, accuracy: 0, avoidance: 0)
            for depth in 1...3 {
                let loot = try saveTestLoot(store.progression, using: &random)
                try store.transaction {
                    try $0.awardXP(floorID: floor, eventID: UUID(), baseAmount: 100)
                    try $0.clearFloor(floorID: floor, performance: performance, loot: loot)
                    if depth == 1 { try $0.equip(loot[0].id, in: .armorCore, maxHealth: 150, maxShield: 150) }
                }
                floor = try store.transaction { try $0.continueRun(after: floor, using: &random) }
            }
            let priorRating = store.progression.rating
            let run = try XCTUnwrap(store.progression.activeRun)
            let loss = try store.progression.rules.loss(entryRating: run.floor.entryRating, difficulty: run.floor.difficulty)
            try store.transaction {
                try $0.awardXP(floorID: floor, eventID: UUID(), baseAmount: 100)
                try $0.takeDamage(floorID: floor, amount: 10000)
            }
            let restored = try saveTestStore(file)
            XCTAssertEqual(restored.progression, store.progression)
            XCTAssertNil(restored.progression.activeRun)
            XCTAssertEqual(restored.progression.experience.lifetime, 460, accuracy: 1e-9)
            XCTAssertEqual(restored.progression.rating, priorRating - loss, accuracy: 1e-9)
            XCTAssertEqual(restored.progression.bankedItems, original.bankedItems)
            XCTAssertEqual(restored.progression.equipped, original.equipped)
            XCTAssertEqual(restored.progression.lastSettlement?.outcome, .died)
        }
    }

    func testRejectedBossClearRollsBackItsXPAndLeavesSavedBytesAlone() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            let floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let before = store.progression
            let bytes = try Data(contentsOf: file)
            let performance = try DelvePerformance(speed: 1, accuracy: 1, avoidance: 1)
            XCTAssertThrowsError(try store.transaction {
                try $0.awardXP(floorID: floor, eventID: UUID(), baseAmount: 50)
                try $0.clearFloor(floorID: floor, performance: performance, loot: [])
            })
            XCTAssertEqual(store.progression, before)
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    func testWriteFailureDoesNotPublishXPOrConsumeItsEvent() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let parent = directory.appendingPathComponent("saves", isDirectory: true)
            let moved = directory.appendingPathComponent("saved-directory", isDirectory: true)
            let file = parent.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            let floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let before = store.progression
            let bytes = try Data(contentsOf: file)
            let event = UUID()
            // A file at the parent path deterministically causes an I/O failure,
            // even when these tests run with permission to write everywhere.
            try FileManager.default.moveItem(at: parent, to: moved)
            try Data("blocked".utf8).write(to: parent)
            XCTAssertThrowsError(try store.transaction { try $0.awardXP(floorID: floor, eventID: event, baseAmount: 100) })
            XCTAssertEqual(store.progression, before)
            XCTAssertEqual(try Data(contentsOf: moved.appendingPathComponent("delve.json")), bytes)
            try FileManager.default.removeItem(at: parent)
            try FileManager.default.moveItem(at: moved, to: parent)
            XCTAssertTrue(try store.transaction { try $0.awardXP(floorID: floor, eventID: event, baseAmount: 100) })
            XCTAssertEqual(try saveTestStore(file).progression, store.progression)
        }
    }

    func testExtractionIsPersistedOnceAndNextRunStartsFresh() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            let floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let loot = try saveTestLoot(store.progression, using: &random)
            let performance = try DelvePerformance(speed: 0, accuracy: 0, avoidance: 0)
            try store.transaction { try $0.clearFloor(floorID: floor, performance: performance, loot: loot) }
            let runID = try XCTUnwrap(store.progression.activeRun).id
            XCTAssertTrue(try store.transaction { try $0.extract(runID: runID) })
            let restored = try saveTestStore(file)
            let count = restored.progression.bankedItems.count
            XCTAssertFalse(try restored.transaction { try $0.extract(runID: runID) })
            XCTAssertEqual(restored.progression.bankedItems.count, count)
            try restored.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            XCTAssertEqual(restored.progression.activeRun?.depth, 1)
            XCTAssertEqual(restored.progression.activeRun?.resources.health, 100)
            XCTAssertEqual(restored.progression.activeRun?.resources.shield, 100)
            XCTAssertThrowsError(try restored.transaction { try $0.extract(runID: runID) })
        }
    }

    func testInvalidLoadedStateCannotResetOrOverwriteAccount() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let original = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
            let replacements: [([String], Any)] = [
                (["progression", "rating"], 0),
                (["progression", "experience", "levelUpCosts"], []),
                (["progression", "experience", "level"], 0),
                (["progression", "experience", "level"], 101),
                (["progression", "experience", "progress"], 100),
                (["progression", "experience", "lifetime"], 20),
                (["progression", "activeRun", "depth"], 0),
                (["progression", "activeRun", "depth"], Int.max),
                (["progression", "activeRun", "resources", "health"], 0),
                (["progression", "activeRun", "resources", "shield"], -1),
                (["progression", "activeRun", "resources", "peakHealth"], 50),
                (["progression", "activeRun", "floor", "difficulty"], 0),
                (["progression", "activeRun", "floor", "phase"], "checkpoint"),
                (["progression", "rules", "difficultySpread"], 0)
            ]
            for (path, value) in replacements {
                var document = original
                replaceJSONValue(value, at: path[...], in: &document)
                let bytes = try JSONSerialization.data(withJSONObject: document)
                try bytes.write(to: file)
                var initialized = false
                XCTAssertThrowsError(try DelveSaveStore(fileURL: file) {
                    initialized = true
                    return try saveTestAccount()
                }, path.joined(separator: "."))
                XCTAssertFalse(initialized)
                XCTAssertEqual(try Data(contentsOf: file), bytes)
            }
        }
    }

    func testUnsupportedAndTruncatedSavesStayUntouched() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let future = Data("{\"format\":\"cubrism.delve\",\"version\":2,\"progression\":\"future schema\"}".utf8)
            try future.write(to: file)
            XCTAssertThrowsError(try saveTestStore(file)) { XCTAssertEqual($0 as? DelveSaveError, .unsupportedVersion(2)) }
            XCTAssertEqual(try Data(contentsOf: file), future)
            let unknown = Data("{\"format\":\"other\",\"version\":1}".utf8)
            try unknown.write(to: file)
            XCTAssertThrowsError(try saveTestStore(file)) { XCTAssertEqual($0 as? DelveSaveError, .unrecognizedFormat) }
            let truncated = Data("{\"format\":\"cubrism.delve\",".utf8)
            try truncated.write(to: file)
            XCTAssertThrowsError(try saveTestStore(file))
            XCTAssertEqual(try Data(contentsOf: file), truncated)
        }
    }

    func testAllThreeCheckpointRewardsMustRetainTheirSampledPower() async throws {
        try await MainActor.run {
            let directory = try saveTestDirectory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("delve.json")
            let store = try saveTestStore(file)
            var random = SaveRandom()
            var floor = try store.transaction { try $0.startRun(maxHealth: 100, maxShield: 100, using: &random) }
            let performance = try DelvePerformance(speed: 0, accuracy: 0, avoidance: 0)
            for depth in 1...6 {
                let loot = try saveTestLoot(store.progression, using: &random)
                try store.transaction { try $0.clearFloor(floorID: floor, performance: performance, loot: loot) }
                if depth < 6 { floor = try store.transaction { try $0.continueRun(after: floor, using: &random) } }
            }
            XCTAssertEqual(store.progression.activeRun?.floor.rewardIDs.count, 3)
            let original = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
            for reward in 0..<3 {
                var document = original
                var account = document["progression"] as! [String: Any]
                var run = account["activeRun"] as! [String: Any]
                var items = run["loot"] as! [[String: Any]]
                items[items.count - 3 + reward]["power"] = 1
                run["loot"] = items
                account["activeRun"] = run
                document["progression"] = account
                let bytes = try JSONSerialization.data(withJSONObject: document)
                try bytes.write(to: file)
                XCTAssertThrowsError(try saveTestStore(file))
                XCTAssertEqual(try Data(contentsOf: file), bytes)
            }
        }
    }
}
