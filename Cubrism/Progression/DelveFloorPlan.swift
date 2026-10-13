import Foundation

enum DelveEnemyKind: String, Codable, CaseIterable {
    case range = "Range", melee = "Melee", tracking = "RangeTracking"
    case suicide = "Suicide", dash = "Dash", triple = "RangeTripple"
    case sludge = "Sludge", bomber = "Bomber", ring = "RangeRing"
    case eliteMelee, eliteRange

    // One more encounter variant becomes eligible for roughly each ordinary
    // +10 clear. Eligibility never guarantees that variant is selected.
    var minimumDifficulty: Double { Double(Self.allCases.firstIndex(of: self)!) * 10 + 1 }
    var points: Double {
        switch self {
        case .tracking, .triple: return 1.5
        case .bomber, .ring, .eliteMelee, .eliteRange: return 2
        default: return 1
        }
    }
    var roomLimit: Int {
        switch self {
        case .range, .melee: return 4
        case .dash: return 2
        default: return 1
        }
    }
    var isElite: Bool { self == .eliteMelee || self == .eliteRange }
    var gameType: String {
        switch self {
        case .eliteMelee: return "Melee"
        case .eliteRange: return "Range"
        default: return rawValue
        }
    }
}

enum DelveBossKind: String, Codable, CaseIterable { case dragon, generator, golem }
enum DelveDensity: Int, Codable, CaseIterable { case sparse = 1, balanced = 2, dense = 3 }

struct DelveRoomPosition: Codable, Equatable, Hashable {
    let x: Int
    let y: Int

    func next(_ direction: DelveDirection) -> Self {
        switch direction {
        case .north: return Self(x: x, y: y + 1)
        case .east: return Self(x: x + 1, y: y)
        case .south: return Self(x: x, y: y - 1)
        case .west: return Self(x: x - 1, y: y)
        }
    }
}

enum DelveDirection: Int, Codable, CaseIterable {
    case north, east, south, west
    var opposite: Self { Self(rawValue: (rawValue + 2) % 4)! }
}

struct DelveSpawnPoint: Codable, Equatable {
    let x: Double
    let y: Double
}

struct DelveEnemySpawn: Codable, Equatable {
    let id: UUID
    let kind: DelveEnemyKind
    let position: DelveSpawnPoint
}

enum DelveEncounter: Codable, Equatable {
    case start
    case combat([DelveEnemySpawn])
    case boss(DelveBossKind)
}

struct DelveRoomPlan: Codable, Equatable {
    let id: UUID
    let position: DelveRoomPosition
    let encounter: DelveEncounter
}

struct DelvePlannedDoor: Equatable {
    let direction: DelveDirection
    let destination: DelveRoomPosition
}

// An ordered route is the complete floor topology: safe start, combat rooms,
// final boss. Only adjacent route entries are linked, even if a winding path
// happens to bring other rooms alongside one another.
struct DelveFloorPlan: Codable, Equatable {
    let difficulty: Double
    let budget: Double
    let groupingMultiplier: Double
    let density: DelveDensity
    let rooms: [DelveRoomPlan]

    var combatRooms: [DelveRoomPlan] {
        rooms.filter { if case .combat = $0.encounter { return true }; return false }
    }
    var enemies: [DelveEnemySpawn] {
        rooms.flatMap { if case .combat(let mobs) = $0.encounter { return mobs }; return [] }
    }
    var spentPoints: Double {
        combatRooms.reduce(0) { total, room in
            guard case .combat(let mobs) = room.encounter else { return total }
            return total + Self.cost(mobs.map(\.kind), groupingMultiplier: groupingMultiplier)
        }
    }

    static func cost(_ enemies: [DelveEnemyKind], groupingMultiplier: Double) -> Double {
        enemies.reduce(0) { $0 + $1.points } * (1 + groupingMultiplier * Double(max(0, enemies.count - 1)))
    }

    func doors(for roomID: UUID) -> [DelvePlannedDoor] {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return [] }
        return [index - 1, index + 1].filter { rooms.indices.contains($0) }.compactMap { neighbor in
            let source = rooms[index].position
            let destination = rooms[neighbor].position
            guard let direction = DelveDirection.allCases.first(where: { source.next($0) == destination }) else { return nil }
            return DelvePlannedDoor(direction: direction, destination: destination)
        }
    }

    func validate() throws {
        try DelveRules.validateScore(difficulty)
        guard budget.isFinite, budget >= 1, groupingMultiplier.isFinite, groupingMultiplier >= 0,
              rooms.count >= 3, Set(rooms.map(\.id)).count == rooms.count,
              Set(rooms.map(\.position)).count == rooms.count,
              rooms.first?.encounter == .start,
              case .boss = rooms.last!.encounter else { throw DelveError.invalidValue("floor plan") }
        for (index, room) in rooms.enumerated() {
            // Bound coordinates before neighbor arithmetic on decoded saves.
            guard abs(Double(room.position.x)) < Double(Int.max / 2),
                  abs(Double(room.position.y)) < Double(Int.max / 2) else { throw DelveError.invalidValue("room position") }
            let expectedDoors = index == 0 || index == rooms.count - 1 ? 1 : 2
            guard doors(for: room.id).count == expectedDoors else { throw DelveError.invalidValue("floor route") }
            if index > 0, index < rooms.count - 1 {
                guard case .combat(let mobs) = room.encounter, !mobs.isEmpty, mobs.count <= density.rawValue else {
                    throw DelveError.invalidValue("encounter")
                }
                for kind in DelveEnemyKind.allCases {
                    guard mobs.filter({ $0.kind == kind }).count <= kind.roomLimit else { throw DelveError.invalidValue("room limit") }
                }
            }
        }
        let mobs = enemies
        guard Set(mobs.map(\.id)).count == mobs.count,
              Set(mobs.map(\.id)).isDisjoint(with: rooms.map(\.id)),
              mobs.allSatisfy({ $0.kind.minimumDifficulty <= difficulty
                  && $0.position.x.isFinite && (0.15...0.85).contains($0.position.x)
                  && $0.position.y.isFinite && (0.20...0.80).contains($0.position.y) }),
              spentPoints <= budget + 1e-9,
              budget - spentPoints < 1 + 1e-9 else { throw DelveError.invalidValue("floor encounters") }
    }
}

struct DelveFloorPlanner {
    // Initial calibration inputs; no floor-count or duration cap. Concurrent
    // pressure consumes more budget, so sparse layouts buy more total mobs.
    var baseBudget = 12.0
    var budgetExponent = 0.1
    var groupingMultiplier = 0.25

    func generate<R: RandomNumberGenerator>(difficulty: Double, density selectedDensity: DelveDensity? = nil,
                                            using random: inout R) throws -> DelveFloorPlan {
        let x = try DelveRules.scalingInput(difficulty)
        guard baseBudget.isFinite, baseBudget >= 1, budgetExponent.isFinite, budgetExponent >= 0,
              groupingMultiplier.isFinite, groupingMultiplier >= 0 else { throw DelveError.invalidValue("floor tuning") }
        // Delve and floor content are intentionally uncapped. The shallow
        // growth curve keeps ordinary/endgame budgets small; do not impose a
        // gameplay ceiling merely to support unrealistic local save edits.
        let budget = baseBudget * pow(1 + x, budgetExponent)
        guard budget.isFinite else { throw DelveError.invalidValue("floor budget") }
        let density = selectedDensity ?? DelveDensity.allCases.randomElement(using: &random)!
        let eligible = DelveEnemyKind.allCases.filter { $0.minimumDifficulty <= difficulty }
        var remaining = budget
        var encounters = [[DelveEnemyKind]]()
        while remaining >= 1 {
            var room = [DelveEnemyKind]()
            while room.count < density.rawValue {
                let choices = eligible.filter { kind in
                    room.filter({ $0 == kind }).count < kind.roomLimit
                        && DelveFloorPlan.cost(room + [kind], groupingMultiplier: groupingMultiplier) <= remaining
                }
                guard let kind = choices.randomElement(using: &random) else { break }
                room.append(kind)
            }
            guard !room.isEmpty else { break }
            remaining -= DelveFloorPlan.cost(room, groupingMultiplier: groupingMultiplier)
            encounters.append(room)
        }

        var position = DelveRoomPosition(x: 0, y: 0)
        var rooms = [DelveRoomPlan(id: UUID(), position: position, encounter: .start)]
        var occupied: Set<DelveRoomPosition> = [position]
        for encounter in encounters {
            // East is always available: monotone columns prevent trapping the
            // generator or introducing a retry loop at long floor lengths.
            let choices = [DelveDirection.north, .east, .south].filter { !occupied.contains(position.next($0)) }
            let direction = choices.randomElement(using: &random)!
            position = position.next(direction)
            occupied.insert(position)
            let mobs = encounter.map { kind in
                DelveEnemySpawn(id: UUID(), kind: kind, position: spawnPoint(entry: direction, using: &random))
            }
            rooms.append(DelveRoomPlan(id: UUID(), position: position, encounter: .combat(mobs)))
        }
        // A horizontal entrance also preserves the authored dragon placement.
        position = position.next(.east)
        rooms.append(DelveRoomPlan(id: UUID(), position: position,
                                   encounter: .boss(DelveBossKind.allCases.randomElement(using: &random)!)))
        let plan = DelveFloorPlan(difficulty: difficulty, budget: budget, groupingMultiplier: groupingMultiplier,
                                 density: density, rooms: rooms)
        try plan.validate()
        return plan
    }

    private func spawnPoint<R: RandomNumberGenerator>(entry: DelveDirection, using random: inout R) -> DelveSpawnPoint {
        // These are the existing 750x375 arena's door-entry positions in unit
        // coordinates. Store the selected position, never redraw it on entry.
        let player: DelveSpawnPoint
        switch entry {
        case .north: player = DelveSpawnPoint(x: 0.5, y: 0.05 + 48.0 / 375)
        case .east: player = DelveSpawnPoint(x: 0.1 + 32.0 / 750, y: 0.5)
        case .south: player = DelveSpawnPoint(x: 0.5, y: 0.95 - 48.0 / 375)
        case .west: player = DelveSpawnPoint(x: 0.9 - 32.0 / 750, y: 0.5)
        }
        func distance(_ point: DelveSpawnPoint) -> Double { hypot((point.x - player.x) * 750, (point.y - player.y) * 375) }
        for _ in 0..<64 {
            let point = DelveSpawnPoint(x: Double.random(in: 0.15...0.85, using: &random),
                                       y: Double.random(in: 0.20...0.80, using: &random))
            if distance(point) > 200 { return point }
        }
        return [DelveSpawnPoint(x: 0.15, y: 0.20), DelveSpawnPoint(x: 0.85, y: 0.20),
                DelveSpawnPoint(x: 0.15, y: 0.80), DelveSpawnPoint(x: 0.85, y: 0.80)].max { distance($0) < distance($1) }!
    }
}
