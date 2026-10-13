import Foundation

struct DelvePoint: Codable, Equatable {
    var x: Double
    var y: Double

    func validate() throws {
        guard x.isFinite, y.isFinite else { throw DelveError.invalidValue("combat position") }
    }
}

// A saved logical timeline, rather than a restarted SKAction. The same motion
// can drive a live node or be advanced in deterministic resume tests.
struct DelveLinearMotion: Codable, Equatable {
    let start: DelvePoint
    let destination: DelvePoint
    let duration: Double
    private(set) var elapsed = 0.0

    init(start: DelvePoint, destination: DelvePoint, duration: Double) throws {
        self.start = start
        self.destination = destination
        self.duration = duration
        try validate()
    }

    var finished: Bool { elapsed == duration }
    var position: DelvePoint {
        let t = elapsed / duration
        return DelvePoint(x: start.x * (1 - t) + destination.x * t,
                           y: start.y * (1 - t) + destination.y * t)
    }

    mutating func advance(seconds: Double) throws {
        guard seconds.isFinite, seconds >= 0 else { throw DelveError.invalidValue("combat delta") }
        elapsed += min(duration - elapsed, seconds)
    }

    func validate() throws {
        try start.validate()
        try destination.validate()
        guard duration.isFinite, duration > 0, elapsed.isFinite, (0...duration).contains(elapsed) else {
            throw DelveError.invalidValue("combat motion")
        }
    }
}

// The cursor is saved with the elapsed time, so a fuse or delayed summon
// cannot replay already-fired effects after restoring or retrying a save.
struct DelveTimedEvents: Codable, Equatable {
    let times: [Double]
    private(set) var elapsed = 0.0
    private(set) var nextIndex = 0

    init(times: [Double]) throws {
        self.times = times
        try validate()
    }

    mutating func advance(seconds: Double) throws -> Range<Int> {
        guard seconds.isFinite, seconds >= 0, (elapsed + seconds).isFinite else {
            throw DelveError.invalidValue("combat delta")
        }
        let previous = nextIndex
        elapsed += seconds
        while nextIndex < times.count, times[nextIndex] <= elapsed { nextIndex += 1 }
        return previous..<nextIndex
    }

    func validate() throws {
        guard !times.isEmpty, times.allSatisfy({ $0.isFinite && $0 > 0 }),
              zip(times, times.dropFirst()).allSatisfy({ $0 < $1 }),
              elapsed.isFinite, elapsed >= 0, (0...times.count).contains(nextIndex),
              nextIndex == times.prefix(while: { $0 <= elapsed }).count else {
            throw DelveError.invalidValue("combat events")
        }
    }
}

struct DelveMotionState: Codable, Equatable {
    let id: UUID
    var movement: DelveLinearMotion
    let lingerSeconds: Double
    private(set) var lingerElapsed = 0.0

    init(id: UUID = UUID(), movement: DelveLinearMotion, lingerSeconds: Double = 0) throws {
        self.id = id
        self.movement = movement
        self.lingerSeconds = lingerSeconds
        try validate()
    }

    var expired: Bool { movement.finished && lingerElapsed == lingerSeconds }

    mutating func advance(seconds: Double) throws {
        guard seconds.isFinite, seconds >= 0 else { throw DelveError.invalidValue("combat delta") }
        let moving = min(seconds, movement.duration - movement.elapsed)
        try movement.advance(seconds: moving)
        lingerElapsed += min(lingerSeconds - lingerElapsed, seconds - moving)
    }

    func validate() throws {
        try movement.validate()
        guard lingerSeconds.isFinite, lingerSeconds >= 0, lingerElapsed.isFinite,
              (0...lingerSeconds).contains(lingerElapsed), movement.finished || lingerElapsed == 0 else {
            throw DelveError.invalidValue("combat motion lifetime")
        }
    }
}

struct DelveRandom: RandomNumberGenerator, Codable, Equatable {
    private(set) var state: UInt64
    init(seed: UInt64) { state = seed }

    // SplitMix64: the full generator state fits in the combat snapshot.
    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
}

struct DelveShotAccounting: Codable, Equatable {
    private(set) var inFlight: Set<UUID> = []
    private(set) var resolved: Set<UUID> = []
    private(set) var hits: Set<UUID> = []

    mutating func fired(_ id: UUID) {
        guard !resolved.contains(id) else { return }
        inFlight.insert(id)
    }

    mutating func resolve(_ id: UUID, hit: Bool) {
        guard inFlight.remove(id) != nil else { return }
        resolved.insert(id)
        if hit { hits.insert(id) }
    }

    // Still-flying shots are neutral when combat ends.
    mutating func finishCombat() { inFlight.removeAll() }
    var accuracy: Double { resolved.isEmpty ? 0 : Double(hits.count) / Double(resolved.count) }

    func validate() throws {
        guard inFlight.isDisjoint(with: resolved), hits.isSubset(of: resolved) else {
            throw DelveError.invalidValue("combat shots")
        }
    }
}

struct DelveCombatMetrics: Codable, Equatable {
    let targetSeconds: Double
    let entryCapacity: Double
    private(set) var activeSeconds = 0.0
    private(set) var damageTaken = 0.0
    var shots = DelveShotAccounting()

    init(targetSeconds: Double, entryCapacity: Double) throws {
        self.targetSeconds = targetSeconds
        self.entryCapacity = entryCapacity
        try validate()
    }

    mutating func recordTime(seconds: Double, combatIsLive: Bool) throws {
        guard seconds.isFinite, seconds >= 0 else { throw DelveError.invalidValue("combat delta") }
        guard combatIsLive else { return }
        guard (activeSeconds + seconds).isFinite else { throw DelveError.invalidValue("combat time") }
        activeSeconds += seconds
    }

    mutating func recordDamage(_ actualDepletion: Double) throws {
        guard actualDepletion.isFinite, actualDepletion >= 0, (damageTaken + actualDepletion).isFinite else {
            throw DelveError.invalidValue("combat damage")
        }
        damageTaken += actualDepletion
    }

    func performance() throws -> DelvePerformance {
        try validate()
        let allowance = entryCapacity * targetSeconds / 60
        return try DelvePerformance(speed: min(1, max(0, 1.5 - activeSeconds / targetSeconds)),
                                     accuracy: shots.accuracy,
                                     avoidance: min(1, max(0, 1 - damageTaken / allowance)))
    }

    func validate() throws {
        try shots.validate()
        guard targetSeconds.isFinite, targetSeconds > 0, entryCapacity.isFinite, entryCapacity > 0,
              activeSeconds.isFinite, activeSeconds >= 0, damageTaken.isFinite, damageTaken >= 0,
              (entryCapacity * targetSeconds / 60).isFinite,
              entryCapacity * targetSeconds / 60 > 0 else { throw DelveError.invalidValue("combat metrics") }
    }
}
