import SpriteKit

// Freeze authored damage ratios and calibrated stats before a floor becomes
// playable. Reopening the save never consults the player's current gear.
enum DelveWorldFactory {
    static func initialWorld(for progression: DelveProgression, random: DelveRandom) throws -> DelveWorldState {
        guard let run = progression.activeRun, run.floor.phase == .combat else { throw DelveError.invalidTransition }
        let plan = run.floor.plan
        let catalog = try stats(difficulty: plan.difficulty, balance: progression.rules.balance)
        let reference = try progression.rules.balance.referenceStats(difficulty: plan.difficulty)
        let ordinaryHP = plan.enemies.reduce(0) { $0 + catalog.enemies[$1.kind]!.health }
        guard case .boss(let boss) = plan.rooms.last!.encounter else { throw DelveError.invalidTransition }
        let target = (ordinaryHP + catalog.bosses[boss]!.health) / reference.damagePerSecond + 2 * Double(plan.combatRooms.count)
        let metrics = try DelveCombatMetrics(targetSeconds: target, entryCapacity: run.resources.maxHealth + run.resources.maxShield)
        let sprite = GameArt.sprite("playerIcon")
        sprite.position = CGPoint(x: GameScene.arenaSize.width / 2, y: GameScene.arenaSize.height / 2)
        sprite.zPosition = 100
        sprite.physicsBody = PlayerEntity.makePhysicsBody(size: sprite.size)
        let player = try DelvePlayerState(pose: DelveSpriteBridge.pose(sprite), body: DelveSpriteBridge.body(sprite.physicsBody),
            cannonRotation: .pi / 2, lastHit: 0, lastShot: -progression.characterStats().shotCooldown)
        let world = DelveWorldState(floorID: run.floor.id, currentRoomID: plan.rooms[0].id,
            completedRoomIDs: [plan.rooms[0].id], clock: 0, started: false, random: random, stats: catalog,
            player: player, actors: [], containers: [], sprites: [], fuses: [], metrics: metrics)
        try world.validate(plan: plan)
        return world
    }

    static func stats(difficulty: Double, balance: DelveBalance) throws -> DelveFloorCombatStats {
        guard let enemies = Constants.jsonDict?["enemy"] as? [String: Any],
              let bosses = Constants.jsonDict?["boss"] as? [String: Any],
              let green = enemies["range"] as? [String: Any],
              let dragon = bosses["dragon"] as? [String: Any] else { throw DelveError.invalidValue("bundled combat definitions") }
        func value(_ key: String, in definition: [String: Any]) throws -> Double {
            guard let number = definition[key] as? NSNumber, number.doubleValue.isFinite else {
                throw DelveError.invalidValue("bundled combat stat \(key)")
            }
            return number.doubleValue
        }
        let baseHealth = try value("healthMult", in: green)
        let baseDamage = try value("rangeAttackMult", in: green) * 25
        let baseBossHealth = try value("healthBase", in: dragon)
        guard baseHealth > 0, baseDamage > 0, baseBossHealth > 0 else { throw DelveError.invalidValue("combat reference") }
        func enemy(_ type: String, elite: Bool = false) throws -> DelveEnemyStats {
            let key = type.prefix(1).lowercased() + String(type.dropFirst())
            guard let definition = enemies[key] as? [String: Any] else { throw DelveError.invalidValue("enemy definition") }
            let relative = try DelveRelativeStats(health: value("healthMult", in: definition) / baseHealth,
                range: value("rangeAttackMult", in: definition) * 25 / baseDamage,
                melee: value("meleeAttackMult", in: definition) * 25 / baseDamage)
            return try balance.enemyStats(difficulty: difficulty, relative: relative, elite: elite)
        }
        let ordinary = try Dictionary(uniqueKeysWithValues: DelveEnemyKind.allCases.map { ($0, try enemy($0.gameType, elite: $0.isElite)) })
        let final = try Dictionary(uniqueKeysWithValues: DelveBossKind.allCases.map { kind -> (DelveBossKind, DelveEnemyStats) in
            guard let definition = bosses[kind.rawValue] as? [String: Any] else { throw DelveError.invalidValue("boss definition") }
            let relative = try DelveRelativeStats(health: value("healthBase", in: definition) / baseBossHealth,
                range: value("rangeBase", in: definition) / baseDamage,
                melee: value("meleeBase", in: definition) / baseDamage,
                effect: value("effectBase", in: definition) / baseDamage)
            return (kind, try balance.enemyStats(difficulty: difficulty, relative: relative, boss: true))
        })
        let result = DelveFloorCombatStats(enemies: ordinary, bosses: final, fireball: try enemy("DragonFireball"))
        try result.validate()
        return result
    }
}
