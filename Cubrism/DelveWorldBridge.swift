import SpriteKit

enum DelveWorldBridge {
    static func capture(room: RoomScene, floorID: UUID, completed: Set<UUID>, stats: DelveFloorCombatStats,
                        metrics: DelveCombatMetrics) throws -> DelveWorldState {
        guard let planned = room.plannedRoom,
              let shooting = Player.entity.component(ofType: PlayerShootComponent.self) else {
            throw DelveError.invalidValue("combat scene")
        }
        var roots = [UUID: SKNode](), parts = [UUID: SKSpriteNode]()
        func addRoot(_ root: SKNode) {
            guard !root.children.isEmpty || root.parent != nil else { return }
            roots[DelveSpriteBridge.id(root)] = root
            for sprite in root.children.compactMap({ $0 as? SKSpriteNode }) { parts[DelveSpriteBridge.id(sprite)] = sprite }
        }
        for root in room.children {
            if root is ShotNode || root.children.contains(where: { $0.physicsBody?.categoryBitMask == Constants.playerShotCategory }) {
                addRoot(root)
            }
        }
        for actor in room.entites {
            let alive = (actor as? EnemyEntity).map { $0.currentHealth > 0 } ?? (actor as? BossEntity).map { $0.currentHealth > 0 } ?? false
            guard alive else { continue }
            for component in DelveActorBridge.actions(actor) {
                for node in DelveBehaviourBridge.referencedNodes(component) {
                    if let sprite = node as? SKSpriteNode {
                        parts[DelveSpriteBridge.id(sprite)] = sprite
                        if let root = sprite.parent as? ShotNode { addRoot(root) }
                    } else if node is ShotNode { addRoot(node) }
                }
            }
        }
        let containers = roots.map { id, root -> DelveProjectileContainer in
            let shot = root as? ShotNode
            let isPlayerShot = root.children.contains { $0.physicsBody?.categoryBitMask == Constants.playerShotCategory }
            return DelveProjectileContainer(id: id, position: DelveSpriteBridge.point(root.position), z: Double(root.zPosition),
                type: shot?.type ?? "player", playerShotID: isPlayerShot ? id : nil,
                rangeDamage: shot?.rangeDamage ?? 0, effectDamage: shot?.effectDamage ?? 0, removesContainerOnHit: shot?.removesContainerOnHit ?? false,
                movement: room.liveMotions[id]?.state, attached: root.scene === room)
        }.sorted { $0.id.uuidString < $1.id.uuidString }
        let sprites = try parts.map { id, sprite -> DelveProjectileSprite in
            let name = sprite.userData?["delveArtName"] as? String
            guard name != nil || sprite.texture == nil else { throw DelveError.invalidValue("unidentified projectile art") }
            let parentID = sprite.parent.map(DelveSpriteBridge.id)
            return DelveProjectileSprite(id: id, containerID: parentID.flatMap { roots[$0] == nil ? nil : $0 },
                image: name ?? "__solidBlack", pose: DelveSpriteBridge.pose(sprite),
                body: DelveSpriteBridge.body(sprite.physicsBody), movement: sprite.scene === room ? room.liveMotions[id]?.state : nil, attached: sprite.scene === room)
        }.sorted { $0.id.uuidString < $1.id.uuidString }
        let player = DelvePlayerState(pose: DelveSpriteBridge.pose(Player.entity.sprite), body: DelveSpriteBridge.body(Player.entity.sprite.physicsBody),
            cannonRotation: Double(Player.entity.cannonSprite.zRotation), lastHit: Player.entity.lastHit, lastShot: shooting.lastShotTime)
        return DelveWorldState(floorID: floorID, currentRoomID: planned.id, completedRoomIDs: completed,
            clock: room.time, started: room.started, random: room.combatRandom, stats: stats, player: player,
            actors: try room.entites.compactMap(DelveActorBridge.capture),
            containers: containers, sprites: sprites, fuses: room.liveFuses.values.filter { $0.sprite?.scene === room }.map(\.state).sorted { $0.spriteID.uuidString < $1.spriteID.uuidString }, metrics: metrics)
    }

    static func restore(_ world: DelveWorldState, plan: DelveFloorPlan, room: RoomScene) throws {
        try world.validate(plan: plan)
        guard room.plannedRoom?.id == world.currentRoomID, room.entites.isEmpty else { throw DelveError.invalidValue("restored room") }
        room.time = world.clock
        room.started = world.started
        room.isPaused = true
        room.liveMotions.removeAll()
        room.liveFuses.removeAll()
        room.combatRandom = world.random
        room.combatStats = world.stats
        var containers = [UUID: ShotNode](), sprites = [UUID: SKSpriteNode]()
        for saved in world.containers {
            let node = ShotNode()
            DelveSpriteBridge.assignID(saved.id, to: node)
            node.position = DelveSpriteBridge.cgPoint(saved.position)
            node.zPosition = CGFloat(saved.z)
            node.type = saved.type
            node.savedRangeDamage = saved.rangeDamage
            node.savedEffectDamage = saved.effectDamage
            node.savedRemovesContainerOnHit = saved.removesContainerOnHit
            containers[saved.id] = node
            if saved.attached { room.addChild(node) }
            if let motion = saved.movement { try room.restoreGameplayMotion(motion, on: node, position: node.position) }
        }
        for saved in world.sprites {
            let sprite: SKSpriteNode
            if saved.image == "__solidBlack" { sprite = SKSpriteNode(color: .black, size: CGSize(width: saved.pose.width, height: saved.pose.height)) }
            else {
                guard GameArt.image(saved.image) != nil else { throw DelveError.invalidValue("projectile art") }
                sprite = GameArt.sprite(saved.image)
            }
            DelveSpriteBridge.assignID(saved.id, to: sprite)
            try DelveSpriteBridge.apply(saved.pose, to: sprite)
            try DelveSpriteBridge.apply(saved.body, to: sprite)
            sprites[saved.id] = sprite
            if let id = saved.containerID { containers[id]?.addChild(sprite) }
            else if saved.attached { room.addChild(sprite) }
            if let motion = saved.movement { try room.restoreGameplayMotion(motion, on: sprite, position: sprite.position) }
        }
        for saved in world.actors {
            let actor = try DelveActorBridge.restore(saved, in: room, sprites: sprites, containers: containers)
            room.entites.append(actor)
        }
        for saved in world.fuses {
            guard let sprite = sprites[saved.spriteID],
                  let bomber = room.entites.compactMap({ $0 as? EnemyEntity }).first(where: { $0.combatID == saved.ownerID }),
                  let component = bomber.component(ofType: EnemyBombDroppingComponent.self) else {
                throw DelveError.invalidValue("restored bomb owner")
            }
            room.liveFuses[saved.spriteID] = DelveLiveFuse(sprite: sprite, state: saved)
            component.nodes.append(sprite)
        }
        switch room.plannedRoom?.encounter {
        case .combat(let spawns):
            room.enemies = spawns.count
            room.killedEnemies = spawns.count - world.actors.count
        case .boss: room.enemies = 1; room.killedEnemies = 0
        default: room.enemies = 0; room.killedEnemies = 0
        }
        try DelveSpriteBridge.apply(world.player.pose, to: Player.entity.sprite)
        try DelveSpriteBridge.apply(world.player.body, to: Player.entity.sprite)
        Player.entity.cannonSprite.zRotation = CGFloat(world.player.cannonRotation)
        Player.entity.lastHit = world.player.lastHit
        Player.entity.component(ofType: PlayerShootComponent.self)?.lastShotTime = world.player.lastShot
        Player.entity.stopControls()
        room.completed = world.completedRoomIDs.contains(world.currentRoomID)
        if room.completed { room.unlockDoors() }
    }
}
