import Foundation
import XCTest
@testable import CubrismProgression

final class DelveAsyncSaveTests: XCTestCase {
    private func directory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @MainActor
    private func store(_ file: URL) throws -> DelveSaveStore {
        try DelveSaveStore(fileURL: file) { try DelveProgression.freshAccount() }
    }

    @MainActor
    func testCombatStagingDoesNotWriteUntilSavedAndReloadKeepsResources() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("delve.json")
        let owner = try store(file)
        var random = SystemRandomNumberGenerator()
        let start = try owner.prepare { try $0.enterDungeon(using: &random) }
        let floor = try await owner.commit(start)
        let bytes = try Data(contentsOf: file)
        try owner.stageCombat { try $0.receiveHit(floorID: floor, rawDamage: 180) }
        XCTAssertTrue(owner.hasUnsavedCombat)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        try await owner.saveCombat()
        XCTAssertFalse(owner.hasUnsavedCombat)
        XCTAssertEqual(try store(file).progression, owner.progression)
        XCTAssertFalse(owner.hasPendingCommit)
    }

    @MainActor
    func testManyOverlappingSnapshotsCannotOverwriteALaterSettlement() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("delve.json")
        let owner = try store(file)
        var random = SystemRandomNumberGenerator()
        let start = try owner.prepare { try $0.enterDungeon(using: &random) }
        let floor = try await owner.commit(start)
        var staged = 0
        let saves = (0..<50).map { _ in
            Task { @MainActor in
                try owner.stageCombat { try $0.receiveHit(floorID: floor, rawDamage: 1) }
                staged += 1
                try await owner.saveCombat()
            }
        }
        // Each task captures/enqueues its save before its first suspension.
        while staged < saves.count { await Task.yield() }
        let settlement = try owner.prepare { try $0.abandon(floorID: floor) }
        try await owner.commit(settlement)
        for save in saves { try await save.value }
        XCTAssertNil(owner.progression.activeRun)
        XCTAssertEqual(owner.progression.lastSettlement?.outcome, .abandoned)
        XCTAssertEqual(try store(file).progression, owner.progression)
        XCTAssertFalse(owner.hasUnsavedCombat)
    }

    @MainActor
    func testFailedCheckpointKeepsOnePreparedLootRollForExactRetry() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let parent = directory.appendingPathComponent("saves", isDirectory: true)
        let moved = directory.appendingPathComponent("backup", isDirectory: true)
        let file = parent.appendingPathComponent("delve.json")
        let owner = try store(file)
        var random = SystemRandomNumberGenerator()
        let start = try owner.prepare { try $0.enterDungeon(using: &random) }
        let floor = try await owner.commit(start)
        for enemy in try XCTUnwrap(owner.progression.activeRun?.floor.plan.enemies) {
            try owner.stageCombat { try $0.awardKill(floorID: floor, enemyID: enemy.id) }
        }
        let before = owner.progression
        let clear = try owner.prepare {
            try $0.finishFloor(floorID: floor, performance: DelvePerformance(speed: 0.7, accuracy: 0.8, avoidance: 0.4), using: &random)
        }
        try FileManager.default.moveItem(at: parent, to: moved)
        try Data("blocked".utf8).write(to: parent)
        do {
            try await owner.commit(clear)
            XCTFail("The blocked path must reject the write")
        } catch { }
        XCTAssertEqual(owner.progression, before)
        XCTAssertTrue(owner.hasPendingCommit)
        XCTAssertThrowsError(try owner.stageCombat { try $0.receiveHit(floorID: floor, rawDamage: 1) })
        XCTAssertThrowsError(try owner.prepare { try $0.abandon(floorID: floor) })
        try FileManager.default.removeItem(at: parent)
        try FileManager.default.moveItem(at: moved, to: parent)
        let committed = try await owner.commit(clear)
        XCTAssertTrue(committed)
        let checkpoint = owner.progression
        let bytes = try Data(contentsOf: file)
        let repeated = try await owner.commit(clear)
        XCTAssertTrue(repeated, "Retry returns the original result")
        XCTAssertEqual(owner.progression, checkpoint)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        XCTAssertEqual(try store(file).progression, checkpoint)
        XCTAssertFalse(owner.hasPendingCommit)
    }

    @MainActor
    func testDeathCannotBeStagedAndMustCommitBeforePublishing() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("delve.json")
        let owner = try store(file)
        var random = SystemRandomNumberGenerator()
        let start = try owner.prepare { try $0.enterDungeon(using: &random) }
        let floor = try await owner.commit(start)
        let original = owner.progression
        XCTAssertThrowsError(try owner.stageCombat { try $0.receiveHit(floorID: floor, rawDamage: 10000) })
        XCTAssertEqual(owner.progression, original)
        let death = try owner.prepare { try $0.receiveHit(floorID: floor, rawDamage: 10000) }
        XCTAssertEqual(owner.progression, original)
        try await owner.commit(death)
        XCTAssertNil(owner.progression.activeRun)
        XCTAssertEqual(owner.progression.lastSettlement?.outcome, .died)
        XCTAssertEqual(try store(file).progression, owner.progression)
    }

    @MainActor
    func testPreparedTokensAreBoundToTheirOwnerAndCannotUndoLaterCommits() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try store(directory.appendingPathComponent("first.json"))
        let second = try store(directory.appendingPathComponent("second.json"))
        var random = SystemRandomNumberGenerator()
        let entry = try first.prepare { try $0.enterDungeon(using: &random) }
        do {
            try await second.commit(entry)
            XCTFail("Another account cannot use a prepared token")
        } catch { XCTAssertEqual(error as? DelveSaveError, .staleTransaction) }
        let floor = try await first.commit(entry)
        let abandoned = try first.prepare { try $0.abandon(floorID: floor) }
        try await first.commit(abandoned)
        let settled = first.progression
        do {
            try await first.commit(entry)
            XCTFail("A stale token cannot restore a settled run")
        } catch { XCTAssertEqual(error as? DelveSaveError, .staleTransaction) }
        XCTAssertEqual(first.progression, settled)
    }
}
