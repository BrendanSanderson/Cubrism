import SpriteKit

enum DelveBehaviourBridge {
    static func capture(_ component: ActionComponent) -> DelveBehaviourState? {
        switch component {
        case let c as EnemyRandomMovementComponent:
            return .randomMovement(DelveMovementState(moving: c.moving, target: DelveSpriteBridge.point(c.moveTo),
                                                       speed: c.moveSpeed, distanceMultiplier: Double(c.distanceMultiplier)))
        case let c as EnemyTrackingComponent: return .tracking(speed: c.moveSpeed)
        case let c as EnemyDashMovementComponent:
            return .dash(DelveMovementState(moving: c.moving, target: DelveSpriteBridge.point(c.moveTo),
                                            speed: c.moveSpeed, finishedMove: c.finishedMove))
        case let c as EnemyShotTargetingComponent:
            return .targeted(DelveShootingState(lastShot: c.lastShotTime, cooldown: c.shotCooldownSeconds))
        case let c as EnemyShotTrackingComponent:
            return .homing(DelveShootingState(lastShot: c.lastShotTime, cooldown: c.shotCooldownSeconds,
                                              length: c.shotLength, speed: c.speed,
                                              projectileID: c.bullet.map { DelveSpriteBridge.id($0) }))
        case let c as EnemyShotTrippleComponent:
            return .triple(DelveBurstState(acting: c.acting, shots: c.shots, lastShot: c.lastShotTime,
                                            direction: c.direction, target: DelveSpriteBridge.point(c.moveTo),
                                            cooldown: c.shotCooldownSeconds, length: c.shotLength))
        case let c as EnemyBombDroppingComponent:
            return .bomb(DelveShootingState(lastShot: c.lastShotTime, cooldown: c.shotCooldown))
        case let c as EnemySludgeDroppingComponent:
            return .sludge(DelveFieldState(acting: c.acting, lastShot: c.lastShotTime, lastDamage: c.lastDamageDealt,
                                            cooldown: c.shotCooldownSeconds, spriteIDs: c.nodes.map { DelveSpriteBridge.id($0) }))
        case let c as EnemyRingShotComponent:
            return .ring(DelveBurstState(acting: c.acting, shots: 0, lastShot: c.lastShotTime,
                                          cooldown: c.shotCooldownSeconds, length: c.shotLength, shotNumber: c.shotNumber))
        case let c as BossShotTargetingComponent:
            return .bossTargeted(DelveShootingState(lastShot: c.lastShotTime, cooldown: c.shotCooldownSeconds, image: c.image))
        case let c as BossSprayComponent:
            return .spray(DelveBurstState(acting: c.acting, shots: c.shots, lastShot: c.lastShot, angle: c.angle))
        case let c as BossElectricFieldComponent:
            return .electric(DelveFieldState(acting: c.acting, lastShot: c.lastShot, triggered: c.exploded,
                                              points: c.points.map(DelveSpriteBridge.point), containerID: containerID(c.node)))
        case let c as BossDragonBreatheComponent:
            return .breathe(DelveBurstState(acting: c.acting, shots: c.shots, lastShot: c.lastShot, startTime: c.shotStart))
        case let c as BossDragonFireballComponent:
            return .fireball(acting: c.acting, lastShot: c.lastShot, fired: c.fired)
        case let c as BossGolemJumpComponent:
            return .jump(DelveJumpState(lastJump: c.lastJump, lastMove: c.lastMoveJump, moves: c.moves, direction: c.direction))
        case let c as BossGolemRockShoot:
            return .rocks(DelveRockState(acting: c.acting, shots: c.shots, lastShot: c.lastShot, startTime: c.startTime,
                                          angles: c.angle.map(Double.init), velocities: c.velocity.map(Double.init),
                                          spriteIDs: c.sprites.map { DelveSpriteBridge.id($0) }))
        case let c as BossTrackingComponent: return .bossTracking(speed: c.moveSpeed)
        case let c as GolemDropComponent:
            return .drop(DelveFieldState(acting: c.acting, lastShot: c.lastShot, lastChange: c.lastChange,
                                          triggered: c.landed, points: c.points.map(DelveSpriteBridge.point), containerID: containerID(c.node)))
        default: return nil // Pose-derived head tilt and cosmetic death/visual components.
        }
    }

    static func referencedNodes(_ component: ActionComponent) -> [SKNode] {
        switch component {
        case let c as EnemyShotTrackingComponent: return [c.node] + (c.bullet.map { [$0] } ?? [])
        case let c as EnemySludgeDroppingComponent: return c.nodes
        case let c as EnemyBombDroppingComponent: return c.nodes
        case let c as BossElectricFieldComponent: return [c.node]
        case let c as BossGolemRockShoot: return c.sprites
        case let c as GolemDropComponent: return [c.node]
        default: return []
        }
    }

    static func restore(_ state: DelveBehaviourState, to component: ActionComponent,
                        sprites: [UUID: SKSpriteNode], containers: [UUID: ShotNode]) throws {
        try state.validate()
        guard capture(component)?.key == state.key else { throw DelveError.invalidValue("behaviour component") }
        switch (state, component) {
        case (.randomMovement(let s), let c as EnemyRandomMovementComponent):
            c.moving = s.moving; c.moveTo = DelveSpriteBridge.cgPoint(s.target)
            c.moveSpeed = s.speed; c.distanceMultiplier = CGFloat(s.distanceMultiplier)
        case (.tracking(let speed), let c as EnemyTrackingComponent): c.moveSpeed = speed
        case (.dash(let s), let c as EnemyDashMovementComponent):
            c.moving = s.moving; c.moveTo = DelveSpriteBridge.cgPoint(s.target)
            c.moveSpeed = s.speed; c.finishedMove = s.finishedMove
        case (.targeted(let s), let c as EnemyShotTargetingComponent):
            c.lastShotTime = s.lastShot; c.shotCooldownSeconds = s.cooldown
        case (.homing(let s), let c as EnemyShotTrackingComponent):
            c.lastShotTime = s.lastShot; c.shotCooldownSeconds = s.cooldown
            c.shotLength = s.length; c.speed = s.speed
            c.node.removeFromParent()
            c.bullet = try s.projectileID.map { try sprite($0, in: sprites) }
            c.node = (c.bullet?.parent as? ShotNode) ?? ShotNode()
            c.node.shooter = c.shooter
        case (.triple(let s), let c as EnemyShotTrippleComponent):
            c.acting = s.acting; c.shots = s.shots; c.lastShotTime = s.lastShot
            c.direction = s.direction; c.moveTo = DelveSpriteBridge.cgPoint(s.target)
            c.shotCooldownSeconds = s.cooldown; c.shotLength = s.length
        case (.bomb(let s), let c as EnemyBombDroppingComponent): c.lastShotTime = s.lastShot; c.shotCooldown = s.cooldown
        case (.sludge(let s), let c as EnemySludgeDroppingComponent):
            c.acting = s.acting; c.lastShotTime = s.lastShot; c.lastDamageDealt = s.lastDamage
            c.shotCooldownSeconds = s.cooldown; c.nodes = try s.spriteIDs.map { try sprite($0, in: sprites) }
        case (.ring(let s), let c as EnemyRingShotComponent):
            c.acting = s.acting; c.lastShotTime = s.lastShot; c.shotCooldownSeconds = s.cooldown
            c.shotLength = s.length; c.shotNumber = s.shotNumber
        case (.bossTargeted(let s), let c as BossShotTargetingComponent): c.lastShotTime = s.lastShot; c.image = s.image
        case (.spray(let s), let c as BossSprayComponent):
            c.acting = s.acting; c.shots = s.shots; c.lastShot = s.lastShot; c.angle = s.angle
        case (.electric(let s), let c as BossElectricFieldComponent):
            c.acting = s.acting; c.lastShot = s.lastShot; c.exploded = s.triggered
            c.points = s.points.map(DelveSpriteBridge.cgPoint); c.node = try container(s.containerID, in: containers)
        case (.breathe(let s), let c as BossDragonBreatheComponent):
            c.acting = s.acting; c.shots = s.shots; c.lastShot = s.lastShot
            c.shotStart = s.startTime; c.currentTime = s.lastShot
        case (.fireball(let acting, let lastShot, let fired), let c as BossDragonFireballComponent):
            c.acting = acting; c.lastShot = lastShot; c.fired = fired
        case (.jump(let s), let c as BossGolemJumpComponent):
            c.lastJump = s.lastJump; c.lastMoveJump = s.lastMove; c.moves = s.moves; c.direction = s.direction
        case (.rocks(let s), let c as BossGolemRockShoot):
            c.acting = s.acting; c.shots = s.shots; c.lastShot = s.lastShot; c.startTime = s.startTime
            c.angle = s.angles.map { CGFloat($0) }; c.velocity = s.velocities.map { CGFloat($0) }
            c.sprites = try s.spriteIDs.map { try sprite($0, in: sprites) }
        case (.bossTracking(let speed), let c as BossTrackingComponent): c.moveSpeed = speed
        case (.drop(let s), let c as GolemDropComponent):
            c.acting = s.acting; c.lastShot = s.lastShot; c.lastChange = s.lastChange; c.landed = s.triggered
            c.points = s.points.map(DelveSpriteBridge.cgPoint); c.node = try container(s.containerID, in: containers)
        default: throw DelveError.invalidValue("behaviour component")
        }
    }

    private static func containerID(_ node: SKNode) -> UUID? {
        node.children.isEmpty && node.parent == nil ? nil : DelveSpriteBridge.id(node)
    }

    private static func sprite(_ id: UUID, in sprites: [UUID: SKSpriteNode]) throws -> SKSpriteNode {
        guard let sprite = sprites[id] else { throw DelveError.invalidValue("behaviour sprite") }
        return sprite
    }

    private static func container(_ id: UUID?, in containers: [UUID: ShotNode]) throws -> ShotNode {
        guard let id = id else { return ShotNode() }
        guard let node = containers[id] else { throw DelveError.invalidValue("behaviour container") }
        return node
    }
}
