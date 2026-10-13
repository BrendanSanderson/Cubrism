import Foundation
import XCTest
@testable import CubrismProgression

final class DelveCombatStateTests: XCTestCase {
    private func restored<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }

    func testMovementResumesAtTheOriginalDestinationWithOnlyRemainingTime() throws {
        var uninterrupted = try DelveLinearMotion(start: DelvePoint(x: 20, y: 100),
                                                   destination: DelvePoint(x: 220, y: 100), duration: 2)
        try uninterrupted.advance(seconds: 0.7)
        XCTAssertEqual(uninterrupted.position.x, 90, accuracy: 1e-12)
        var resumed = try restored(uninterrupted)
        try resumed.validate()
        // No simulation ticks occur during pause/background, regardless of
        // elapsed wall time. The first resumed tick advances just that frame.
        try resumed.advance(seconds: 0.4)
        try uninterrupted.advance(seconds: 0.4)
        XCTAssertEqual(resumed, uninterrupted)
        XCTAssertEqual(resumed.position.x, 130, accuracy: 1e-12)
        try resumed.advance(seconds: 0.9)
        try uninterrupted.advance(seconds: 0.9)
        XCTAssertEqual(resumed, uninterrupted)
        XCTAssertTrue(resumed.finished)
        XCTAssertEqual(resumed.position, DelvePoint(x: 220, y: 100))
        try resumed.advance(seconds: 1000)
        XCTAssertEqual(resumed.position, DelvePoint(x: 220, y: 100))
    }

    func testDelayedExplosionsResumeTheirCursorAndNeverRepeatFiredEvents() throws {
        var events = try DelveTimedEvents(times: [4, 4.33, 4.66, 4.99])
        XCTAssertEqual(try events.advance(seconds: 4.4), 0..<2)
        var resumed = try restored(events)
        try resumed.validate()
        XCTAssertEqual(try resumed.advance(seconds: 0), 2..<2)
        XCTAssertEqual(try resumed.advance(seconds: 0.3), 2..<3)
        let again = try restored(resumed)
        resumed = again
        XCTAssertEqual(try resumed.advance(seconds: 1), 3..<4)
        XCTAssertEqual(try resumed.advance(seconds: 1000), 4..<4)
        try resumed.validate()
    }

    func testSavedRandomStateContinuesTheSameRuntimeSequence() throws {
        var uninterrupted = DelveRandom(seed: 854)
        for _ in 0..<70 { _ = uninterrupted.next() }
        var resumed = try restored(uninterrupted)
        for _ in 0..<1000 { XCTAssertEqual(resumed.next(), uninterrupted.next()) }
        XCTAssertEqual(resumed, uninterrupted)
        var other = DelveRandom(seed: 855)
        XCTAssertNotEqual(resumed.next(), other.next())
    }

    func testPerformanceExcludesInactiveTimeAndUnresolvedShotsAndCountsEachHitOnce() throws {
        var metrics = try DelveCombatMetrics(targetSeconds: 60, entryCapacity: 300)
        try metrics.recordTime(seconds: 60, combatIsLive: true)
        try metrics.recordTime(seconds: 10000, combatIsLive: false)
        try metrics.recordDamage(75)
        let hit = UUID(), miss = UUID(), pending = UUID()
        metrics.shots.fired(hit)
        metrics.shots.fired(miss)
        metrics.shots.fired(pending)
        metrics.shots.resolve(hit, hit: true)
        metrics.shots.resolve(hit, hit: true)
        metrics.shots.resolve(miss, hit: false)
        metrics.shots.resolve(UUID(), hit: true)
        metrics = try restored(metrics)
        metrics.shots.finishCombat()
        metrics.shots.resolve(pending, hit: true)
        let result = try metrics.performance()
        XCTAssertEqual(result.speed, 0.5)
        XCTAssertEqual(result.accuracy, 0.5)
        XCTAssertEqual(result.avoidance, 0.75)
        XCTAssertEqual(result.score, 0.55, accuracy: 1e-12)
        XCTAssertEqual(metrics.damageTaken, 75, "Regeneration cannot erase recorded depletion")
        XCTAssertEqual(metrics.shots.resolved.count, 2)
    }

    func testCorruptTimelinesAndInvalidDeltasFailBeforeSimulation() throws {
        var motion = try DelveLinearMotion(start: DelvePoint(x: 1, y: 2), destination: DelvePoint(x: 3, y: 4), duration: 1)
        let original = motion
        XCTAssertThrowsError(try motion.advance(seconds: -1))
        XCTAssertEqual(motion, original)
        XCTAssertThrowsError(try DelveLinearMotion(start: DelvePoint(x: .nan, y: 1), destination: DelvePoint(x: 1, y: 1), duration: 1))
        XCTAssertThrowsError(try DelveTimedEvents(times: [4, 3]))
        XCTAssertThrowsError(try DelveTimedEvents(times: [4, 4]))
        let corrupt = Data("{\"times\":[4,5],\"elapsed\":4.5,\"nextIndex\":0}".utf8)
        let events = try JSONDecoder().decode(DelveTimedEvents.self, from: corrupt)
        XCTAssertThrowsError(try events.validate())
        XCTAssertThrowsError(try DelveCombatMetrics(targetSeconds: 0, entryCapacity: 300))
        XCTAssertThrowsError(try DelveCombatMetrics(targetSeconds: 60, entryCapacity: 0))
    }
}
