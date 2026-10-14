import Foundation

struct DelvePose: Codable, Equatable {
    var position: DelvePoint
    var width: Double
    var height: Double
    var rotation = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var z = 0.0
    var alpha = 1.0

    func validate() throws {
        try position.validate()
        try finite([width, height, rotation, scaleX, scaleY, z, alpha])
        guard width > 0, height > 0, scaleX != 0, scaleY != 0, (0...1).contains(alpha) else {
            throw DelveError.invalidValue("combat pose")
        }
    }
}

struct DelveBodyState: Codable, Equatable {
    var category: UInt32
    var collision: UInt32
    var contact: UInt32
    var dynamic: Bool
    var allowsRotation: Bool
    var gravity: Bool
    var precise: Bool
    var velocity: DelvePoint
    var angularVelocity: Double
    var mass: Double
    var friction: Double
    var restitution: Double
    var linearDamping: Double
    var angularDamping: Double

    func validate() throws {
        try velocity.validate()
        try finite([angularVelocity, mass, friction, restitution, linearDamping, angularDamping])
        guard mass > 0, [friction, restitution, linearDamping, angularDamping].allSatisfy({ $0 >= 0 }) else {
            throw DelveError.invalidValue("combat body")
        }
    }
}

struct DelveMovementState: Codable, Equatable {
    var moving: Bool
    var target: DelvePoint
    var speed: Double
    var distanceMultiplier = 1.0
    var finishedMove = 0.0

    func validate() throws {
        try target.validate()
        try finite([speed, distanceMultiplier, finishedMove])
        guard speed >= 0, distanceMultiplier > 0 else { throw DelveError.invalidValue("movement behaviour") }
    }
}

struct DelveShootingState: Codable, Equatable {
    var lastShot: Double
    var cooldown: Double
    var length = 0.0
    var speed = 0.0
    var projectileID: UUID?
    var image: String?

    func validate() throws {
        try finite([lastShot, cooldown, length, speed])
        guard cooldown > 0, length >= 0, speed >= 0 else { throw DelveError.invalidValue("shooting behaviour") }
    }
}

struct DelveBurstState: Codable, Equatable {
    var acting: Bool
    var shots: Int
    var lastShot: Double
    var startTime = 0.0
    var angle = 0.0
    var direction = 0
    var target = DelvePoint(x: 0, y: 0)
    var cooldown = 1.0
    var length = 0.0
    var shotNumber = 0

    func validate() throws {
        try target.validate()
        try finite([lastShot, startTime, angle, cooldown, length])
        guard shots >= 0, direction >= 0, cooldown > 0, length >= 0, shotNumber >= 0 else {
            throw DelveError.invalidValue("burst behaviour")
        }
    }
}

struct DelveFieldState: Codable, Equatable {
    var acting: Bool
    var lastShot: Double
    var lastChange = 0.0
    var lastDamage = 0.0
    var cooldown = 1.0
    var triggered = false
    var points: [DelvePoint] = []
    var containerID: UUID?
    var spriteIDs: [UUID] = []

    func validate() throws {
        try finite([lastShot, lastChange, lastDamage, cooldown])
        guard cooldown > 0, Set(spriteIDs).count == spriteIDs.count else {
            throw DelveError.invalidValue("field behaviour")
        }
        for point in points { try point.validate() }
    }
}

struct DelveJumpState: Codable, Equatable {
    var lastJump: Double
    var lastMove: Double
    var moves: Int
    var direction: Int

    func validate() throws {
        try finite([lastJump, lastMove])
        guard (0..<8).contains(moves), (0...2).contains(direction) else {
            throw DelveError.invalidValue("golem jump")
        }
    }
}

struct DelveRockState: Codable, Equatable {
    var acting: Bool
    var shots: Int
    var lastShot: Double
    var startTime: Double
    var angles: [Double]
    var velocities: [Double]
    var spriteIDs: [UUID]

    func validate() throws {
        try finite([lastShot, startTime] + angles + velocities)
        guard (0...6).contains(shots), angles.count == velocities.count,
              acting ? (angles.count == 6 && spriteIDs.count == shots) : (angles.isEmpty && spriteIDs.isEmpty),
              Set(spriteIDs).count == spriteIDs.count, velocities.allSatisfy({ $0 >= 0 }) else {
            throw DelveError.invalidValue("golem rocks")
        }
    }
}

enum DelveBehaviourState: Codable, Equatable {
    case randomMovement(DelveMovementState), tracking(speed: Double), dash(DelveMovementState)
    case targeted(DelveShootingState), homing(DelveShootingState), triple(DelveBurstState)
    case bomb(DelveShootingState), sludge(DelveFieldState), ring(DelveBurstState)
    case bossTargeted(DelveShootingState), spray(DelveBurstState), electric(DelveFieldState)
    case breathe(DelveBurstState), fireball(acting: Bool, lastShot: Double, fired: Bool)
    case jump(DelveJumpState), rocks(DelveRockState), bossTracking(speed: Double), drop(DelveFieldState)

    var key: String {
        switch self {
        case .randomMovement: return "randomMovement"
        case .tracking: return "tracking"
        case .dash: return "dash"
        case .targeted: return "targeted"
        case .homing: return "homing"
        case .triple: return "triple"
        case .bomb: return "bomb"
        case .sludge: return "sludge"
        case .ring: return "ring"
        case .bossTargeted: return "bossTargeted"
        case .spray: return "spray"
        case .electric: return "electric"
        case .breathe: return "breathe"
        case .fireball: return "fireball"
        case .jump: return "jump"
        case .rocks: return "rocks"
        case .bossTracking: return "bossTracking"
        case .drop: return "drop"
        }
    }

    var referencedSprites: [UUID] {
        switch self {
        case .homing(let state): return state.projectileID.map { [$0] } ?? []
        case .sludge(let state): return state.spriteIDs
        case .rocks(let state): return state.spriteIDs
        default: return []
        }
    }

    var referencedContainer: UUID? {
        switch self {
        case .electric(let state), .drop(let state): return state.containerID
        default: return nil
        }
    }

    func validate() throws {
        switch self {
        case .randomMovement(let s), .dash(let s): try s.validate()
        case .tracking(let speed), .bossTracking(let speed):
            try finite([speed]); guard speed >= 0 else { throw DelveError.invalidValue("tracking speed") }
        case .targeted(let s), .homing(let s), .bomb(let s), .bossTargeted(let s): try s.validate()
        case .triple(let s), .ring(let s), .spray(let s), .breathe(let s): try s.validate()
        case .sludge(let s), .electric(let s), .drop(let s): try s.validate()
        case .jump(let s): try s.validate()
        case .rocks(let s): try s.validate()
        case .fireball(_, let lastShot, _): try finite([lastShot])
        }
    }
}

enum DelveActorKind: Codable, Equatable {
    case enemy(DelveEnemyKind), boss(DelveBossKind), fireball

    var behaviourKeys: Set<String> {
        switch self {
        case .enemy(.range), .enemy(.eliteRange): return ["randomMovement", "targeted"]
        case .enemy(.melee), .enemy(.eliteMelee), .enemy(.suicide), .fireball: return ["tracking"]
        case .enemy(.dash): return ["dash"]
        case .enemy(.tracking): return ["randomMovement", "homing"]
        case .enemy(.triple): return ["randomMovement", "triple"]
        case .enemy(.sludge): return ["randomMovement", "sludge"]
        case .enemy(.bomber): return ["randomMovement", "bomb"]
        case .enemy(.ring): return ["ring"]
        case .boss(.dragon): return ["bossTargeted", "breathe", "fireball"]
        case .boss(.generator): return ["bossTargeted", "spray", "electric"]
        case .boss(.golem): return ["drop", "rocks", "jump", "bossTracking"]
        }
    }
}

struct DelveBossPhase: Codable, Equatable {
    var firstAttack: Bool
    var selectedAttack: String?
    var lastShot: Double
}

struct DelveActorState: Codable, Equatable {
    let id: UUID
    let kind: DelveActorKind
    var pose: DelvePose
    var body: DelveBodyState?
    var health: Double
    let stats: DelveEnemyStats
    var behaviours: [DelveBehaviourState]
    var bossPhase: DelveBossPhase?
    var rootZ = 0.0

    func validate() throws {
        try pose.validate()
        try body?.validate()
        try stats.validate()
        try finite([rootZ])
        guard health.isFinite, health > 0, health <= stats.health,
              Set(behaviours.map(\.key)).count == behaviours.count,
              Set(behaviours.map(\.key)) == kind.behaviourKeys else { throw DelveError.invalidValue("combat actor") }
        for behaviour in behaviours { try behaviour.validate() }
        if let phase = bossPhase {
            guard case .boss = kind else { throw DelveError.invalidValue("boss phase") }
            try finite([phase.lastShot])
            guard phase.firstAttack || phase.selectedAttack != nil,
                  phase.selectedAttack == nil || behaviours.contains(where: { $0.key == phase.selectedAttack }) else {
                throw DelveError.invalidValue("boss attack")
            }
        } else if case .boss = kind { throw DelveError.invalidValue("boss phase") }
    }
}

struct DelveProjectileContainer: Codable, Equatable {
    let id: UUID
    var position: DelvePoint
    var z: Double
    var type: String
    var playerShotID: UUID?
    var rangeDamage: Double
    var effectDamage: Double
    var removesContainerOnHit = false
    var movement: DelveMotionState?
    var attached = true
}

struct DelveProjectileSprite: Codable, Equatable {
    let id: UUID
    let containerID: UUID?
    var image: String
    var pose: DelvePose
    var body: DelveBodyState?
    var movement: DelveMotionState?
    // Some rock/homing components retain an expired detached sprite until
    // their attack phase ends. Preserve that reference without rendering it.
    var attached: Bool
}

struct DelveBombFuse: Codable, Equatable {
    let spriteID: UUID
    let ownerID: UUID
    var events: DelveTimedEvents
    var damage: Double
}

struct DelvePlayerState: Codable, Equatable {
    var pose: DelvePose
    var body: DelveBodyState?
    var cannonRotation: Double
    var lastHit: Double
    var lastShot: Double
}

struct DelveFloorCombatStats: Codable, Equatable {
    let enemies: [DelveEnemyKind: DelveEnemyStats]
    let bosses: [DelveBossKind: DelveEnemyStats]
    let fireball: DelveEnemyStats

    func validate() throws {
        guard Set(enemies.keys) == Set(DelveEnemyKind.allCases),
              Set(bosses.keys) == Set(DelveBossKind.allCases) else { throw DelveError.invalidValue("floor stats") }
        for stats in Array(enemies.values) + Array(bosses.values) + [fireball] { try stats.validate() }
    }
}

// Resources/XP/ownership live only in DelveProgression. This value describes
// the paused simulation: it contains no SpriteKit objects or input intent.
struct DelveWorldState: Codable, Equatable {
    let floorID: UUID
    var currentRoomID: UUID
    var completedRoomIDs: Set<UUID>
    var clock: Double
    var started: Bool
    var random: DelveRandom
    let stats: DelveFloorCombatStats
    var player: DelvePlayerState
    var actors: [DelveActorState]
    var containers: [DelveProjectileContainer]
    var sprites: [DelveProjectileSprite]
    var fuses: [DelveBombFuse]
    var metrics: DelveCombatMetrics

    func validate(plan: DelveFloorPlan) throws {
        try plan.validate()
        try stats.validate()
        try player.pose.validate()
        try player.body?.validate()
        try metrics.validate()
        try finite([clock, player.cannonRotation, player.lastHit, player.lastShot])
        let roomIDs = Set(plan.rooms.map(\.id))
        let completedPrefix = plan.rooms.prefix { completedRoomIDs.contains($0.id) }.count
        guard let currentIndex = plan.rooms.firstIndex(where: { $0.id == currentRoomID }),
              clock >= 0, completedPrefix >= 1, completedPrefix == completedRoomIDs.count,
              currentIndex <= completedPrefix, !completedRoomIDs.contains(plan.rooms.last!.id),
              completedRoomIDs.isSubset(of: roomIDs),
              Set(actors.map(\.id)).count == actors.count,
              Set(containers.map(\.id)).count == containers.count,
              Set(sprites.map(\.id)).count == sprites.count,
              Set(fuses.map(\.spriteID)).count == fuses.count else { throw DelveError.invalidValue("combat world") }
        let containerIDs = Set(containers.map(\.id)), spriteIDs = Set(sprites.map(\.id))
        let playerShotIDs = containers.compactMap(\.playerShotID)
        guard Set(playerShotIDs).count == playerShotIDs.count,
              metrics.shots.inFlight.isSubset(of: Set(playerShotIDs)) else {
            throw DelveError.invalidValue("projectile accounting")
        }
        let currentRoom = plan.rooms[currentIndex]
        if case .boss(let kind) = currentRoom.encounter {
            guard actors.filter({ $0.id == currentRoomID && $0.kind == .boss(kind) }).count == 1 else {
                throw DelveError.invalidValue("missing planned boss")
            }
        }
        if completedRoomIDs.contains(currentRoomID), !actors.isEmpty { throw DelveError.invalidValue("cleared room actors") }
        for actor in actors {
            try actor.validate()
            switch (actor.kind, currentRoom.encounter) {
            case (.enemy(let kind), .combat(let spawns)):
                guard spawns.contains(where: { $0.id == actor.id && $0.kind == kind }), actor.stats == stats.enemies[kind] else {
                    throw DelveError.invalidValue("planned actor")
                }
            case (.boss(let kind), .boss(let planned)):
                let allowed = kind == .dragon ? ["breathe", "fireball"] : (kind == .generator ? ["spray", "electric"] : ["drop", "rocks"])
                guard kind == planned, actor.id == currentRoomID, actor.stats == stats.bosses[kind],
                      actor.bossPhase?.selectedAttack == nil || allowed.contains(actor.bossPhase!.selectedAttack!) else {
                    throw DelveError.invalidValue("planned boss")
                }
            case (.fireball, .boss(.dragon)):
                guard actor.stats == stats.fireball else { throw DelveError.invalidValue("summon stats") }
            default: throw DelveError.invalidValue("room actor")
            }
            for behaviour in actor.behaviours {
                guard Set(behaviour.referencedSprites).isSubset(of: spriteIDs),
                      behaviour.referencedContainer == nil || containerIDs.contains(behaviour.referencedContainer!) else {
                    throw DelveError.invalidValue("combat references")
                }
            }
        }
        for container in containers {
            try container.position.validate()
            try finite([container.z, container.rangeDamage, container.effectDamage])
            try container.movement?.validate()
            guard container.rangeDamage >= 0, container.effectDamage >= 0,
                  container.movement == nil || (container.movement?.id == container.id && container.movement?.expired == false) else {
                throw DelveError.invalidValue("projectile damage or movement")
            }
        }
        for sprite in sprites {
            try sprite.pose.validate()
            try sprite.body?.validate()
            try sprite.movement?.validate()
            guard !sprite.image.isEmpty, sprite.containerID == nil || containerIDs.contains(sprite.containerID!),
                  sprite.movement == nil || (sprite.movement?.id == sprite.id && sprite.movement?.expired == false) else {
                throw DelveError.invalidValue("projectile sprite")
            }
        }
        for fuse in fuses {
            try fuse.events.validate()
            guard sprites.contains(where: { $0.id == fuse.spriteID && $0.attached }),
                  actors.contains(where: { $0.id == fuse.ownerID && $0.kind == .enemy(.bomber) }),
                  fuse.events.times == [4, 4.33, 4.66, 4.99], fuse.events.nextIndex < 4,
                  fuse.damage.isFinite, fuse.damage >= 0 else {
                throw DelveError.invalidValue("bomb fuse")
            }
        }
    }
}

extension DelveEnemyStats {
    func validate() throws {
        try finite([health, rangeAttackPower, meleeAttackPower, effectAttackPower])
        guard health > 0, [rangeAttackPower, meleeAttackPower, effectAttackPower].allSatisfy({ $0 >= 0 }) else {
            throw DelveError.invalidValue("enemy stats")
        }
    }
}

private func finite(_ values: [Double]) throws {
    guard values.allSatisfy(\.isFinite) else { throw DelveError.invalidValue("combat scalar") }
}
