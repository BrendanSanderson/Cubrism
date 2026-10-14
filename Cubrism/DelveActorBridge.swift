import SpriteKit

enum DelveActorBridge {
    static func actions(_ actor: DynamicEntity) -> [ActionComponent] {
        if let enemy = actor as? EnemyEntity { return enemy.actions }
        if let boss = actor as? BossEntity { return boss.actions + boss.constantActions }
        return []
    }

    static func capture(_ actor: DynamicEntity) throws -> DelveActorState? {
        if let enemy = actor as? EnemyEntity {
            guard enemy.currentHealth > 0 else { return nil }
            let kind: DelveActorKind
            if enemy.type == "DragonFireball" { kind = .fireball }
            else {
                guard let type = DelveEnemyKind.allCases.first(where: { $0.gameType == enemy.type && $0.isElite == enemy.isElite }) else {
                    throw DelveError.invalidValue("enemy kind")
                }
                kind = .enemy(type)
            }
            let state = DelveActorState(id: enemy.combatID, kind: kind, pose: DelveSpriteBridge.pose(enemy.sprite),
                body: DelveSpriteBridge.body(enemy.sprite.physicsBody), health: enemy.currentHealth,
                stats: DelveEnemyStats(health: enemy.health, rangeAttackPower: enemy.rangeAttackPower,
                                       meleeAttackPower: enemy.meleeAttackPower, effectAttackPower: 0),
                behaviours: enemy.actions.compactMap(DelveBehaviourBridge.capture), rootZ: Double(enemy.node.zPosition))
            try state.validate()
            return state
        }
        if let boss = actor as? BossEntity {
            guard boss.currentHealth > 0 else { return nil }
            guard let kind = DelveBossKind(rawValue: boss.type) else { throw DelveError.invalidValue("boss kind") }
            let selected = boss.attack.flatMap(DelveBehaviourBridge.capture)?.key
            let state = DelveActorState(id: boss.combatID, kind: .boss(kind), pose: DelveSpriteBridge.pose(boss.sprite),
                body: DelveSpriteBridge.body(boss.sprite.physicsBody), health: boss.currentHealth,
                stats: DelveEnemyStats(health: boss.health, rangeAttackPower: boss.rangeAttackPower,
                                       meleeAttackPower: boss.meleeAttackPower, effectAttackPower: boss.effectAttackPower),
                behaviours: actions(boss).compactMap(DelveBehaviourBridge.capture),
                bossPhase: DelveBossPhase(firstAttack: boss.firstAttack, selectedAttack: selected, lastShot: boss.lastShot),
                rootZ: Double(boss.node.zPosition))
            try state.validate()
            return state
        }
        return nil
    }

    static func restore(_ state: DelveActorState, in room: RoomScene,
                        sprites: [UUID: SKSpriteNode], containers: [UUID: ShotNode]) throws -> DynamicEntity {
        try state.validate()
        let actor: DynamicEntity
        let sprite: SKSpriteNode
        switch state.kind {
        case .enemy, .fireball:
            let type: String, elite: Bool
            if case .enemy(let kind) = state.kind { type = kind.gameType; elite = kind.isElite }
            else { type = "DragonFireball"; elite = false }
            let enemy = EnemyEntity(scene: room, eType: type, lev: elite ? 5 : 1, elite: elite,
                                     position: DelveSpriteBridge.cgPoint(state.pose.position), stats: state.stats)
            enemy.combatID = state.id
            enemy.delveSpawnID = state.kind == .fireball ? nil : state.id
            enemy.currentHealth = state.health
            enemy.node.zPosition = CGFloat(state.rootZ)
            actor = enemy; sprite = enemy.sprite
        case .boss(let kind):
            let image = kind == .dragon ? "dragonBoss" : (kind == .generator ? "generatorBoss" : "golemBoss")
            let boss = BossEntity(scene: room, properties: ["name": kind.rawValue, "image": image, "size": 100, "position": "center"],
                                    stats: state.stats, combatID: state.id)
            boss.currentHealth = state.health
            boss.node.zPosition = CGFloat(state.rootZ)
            actor = boss; sprite = boss.sprite
        }
        try DelveSpriteBridge.apply(state.pose, to: sprite)
        try DelveSpriteBridge.apply(state.body, to: sprite)
        let components = actions(actor)
        for saved in state.behaviours {
            guard let component = components.first(where: { DelveBehaviourBridge.capture($0)?.key == saved.key }) else {
                throw DelveError.invalidValue("missing behaviour")
            }
            try DelveBehaviourBridge.restore(saved, to: component, sprites: sprites, containers: containers)
        }
        if let boss = actor as? BossEntity, let phase = state.bossPhase {
            boss.firstAttack = phase.firstAttack
            boss.lastShot = phase.lastShot
            boss.attack = boss.actions.first { DelveBehaviourBridge.capture($0)?.key == phase.selectedAttack }
            boss.component(ofType: BossBarComponent.self)?.updateBars(state.health, totalHealth: state.stats.health)
        } else if let enemy = actor as? EnemyEntity { enemy.damageEnemy(0) }
        return actor
    }
}
