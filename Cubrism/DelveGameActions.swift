import SpriteKit

private extension DelvePoint {
    init(_ point: CGPoint) { self.init(x: Double(point.x), y: Double(point.y)) }
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

final class DelveLiveMotion {
    weak var node: SKNode?
    var state: DelveMotionState

    init(node: SKNode, state: DelveMotionState) {
        self.node = node
        self.state = state
    }
}

extension GameScene {
    // All call sites supply authored finite positions/durations. Throwing
    // validation remains available at the save/restore boundary.
    func moveGameplayNode(_ node: SKNode, to destination: CGPoint, duration: Double, linger: Double = 0) {
        if !usesRestorableCombat {
            node.run(.sequence([.move(to: destination, duration: duration),
                                .wait(forDuration: linger), .removeFromParent()]))
            return
        }
        let movement = try! DelveLinearMotion(start: DelvePoint(node.position),
                                               destination: DelvePoint(destination), duration: duration)
        let state = try! DelveMotionState(movement: movement, lingerSeconds: linger)
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["delveNodeID"] = state.id.uuidString
        liveMotions[state.id] = DelveLiveMotion(node: node, state: state)
    }

    func restoreGameplayMotion(_ state: DelveMotionState, on node: SKNode, position: CGPoint? = nil) throws {
        try state.validate()
        guard !state.expired, liveMotions[state.id] == nil else { throw DelveError.invalidValue("live motion") }
        node.removeAllActions()
        node.position = position ?? state.movement.position.cgPoint
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["delveNodeID"] = state.id.uuidString
        liveMotions[state.id] = DelveLiveMotion(node: node, state: state)
    }

    var gameplayMotionSnapshot: [DelveMotionState] {
        liveMotions.values.filter { $0.node?.scene === self }.map(\.state)
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    func advanceGameplayMotions(seconds: Double) {
        guard usesRestorableCombat, !isPaused else { return }
        for (id, live) in liveMotions {
            guard let node = live.node, node.scene === self else {
                liveMotions[id] = nil
                continue
            }
            try! live.state.advance(seconds: seconds)
            node.position = live.state.movement.position.cgPoint
            if live.state.expired {
                node.removeFromParent()
                liveMotions[id] = nil
            }
        }
        for wrapper in children.compactMap({ $0 as? ShotNode }) where wrapper.children.isEmpty {
            wrapper.removeFromParent()
        }
    }
}

final class DelveLiveFuse {
    weak var sprite: SKSpriteNode?
    var state: DelveBombFuse
    init(sprite: SKSpriteNode, state: DelveBombFuse) { self.sprite = sprite; self.state = state }
}

extension GameScene {
    func randomInteger(upperBound: UInt32) -> UInt32 {
        guard upperBound > 0 else { return 0 }
        return usesRestorableCombat ? UInt32.random(in: 0..<upperBound, using: &combatRandom) : arc4random_uniform(upperBound)
    }

    func randomUnit() -> Double {
        usesRestorableCombat ? Double.random(in: 0..<1, using: &combatRandom) : Double(arc4random()) / Double(UInt32.max)
    }

    func randomCoordinate(in range: ClosedRange<CGFloat>) -> CGFloat {
        usesRestorableCombat ? CGFloat.random(in: range, using: &combatRandom) : CGFloat.random(in: range)
    }

    func armBomb(_ sprite: SKSpriteNode, owner: EnemyEntity) {
        let id = DelveSpriteBridge.id(sprite)
        let state = DelveBombFuse(spriteID: id, ownerID: owner.combatID,
                                  events: try! DelveTimedEvents(times: [4, 4.33, 4.66, 4.99]),
                                  damage: owner.rangeAttackPower)
        liveFuses[id] = DelveLiveFuse(sprite: sprite, state: state)
        updateBombArt(sprite, elapsed: 0)
    }

    func cancelBombs(ownerID: UUID) {
        for (id, fuse) in liveFuses where fuse.state.ownerID == ownerID {
            fuse.sprite?.parent?.removeFromParent()
            liveFuses[id] = nil
        }
    }

    func advanceBombFuses(seconds: Double) {
        guard usesRestorableCombat, !isPaused else { return }
        for id in liveFuses.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let fuse = liveFuses[id], let sprite = fuse.sprite, sprite.scene === self else {
                liveFuses[id] = nil
                continue
            }
            let effects = try! fuse.state.events.advance(seconds: seconds)
            for _ in effects { emitBombFragments(at: sprite.position, damage: fuse.state.damage) }
            updateBombArt(sprite, elapsed: fuse.state.events.elapsed)
            if fuse.state.events.nextIndex == 4 {
                sprite.parent?.removeFromParent()
                liveFuses[id] = nil
            }
        }
    }

    private func updateBombArt(_ sprite: SKSpriteNode, elapsed: Double) {
        let image = elapsed < 4 ? "bombLit\(min(3, Int(elapsed) + 1))" : "bossDragonShot1"
        sprite.texture = GameArt.texture(image)
        sprite.userData?["delveArtName"] = image
    }

    private func emitBombFragments(at position: CGPoint, damage: Double) {
        let root = ShotNode()
        root.savedRangeDamage = damage
        addChild(root)
        for index in 0..<16 {
            let angle = Double(index) * .pi / 8
            let sprite = GameArt.sprite("bossDragonShot\(randomInteger(upperBound: 4))")
            sprite.position = position
            root.addChild(sprite)
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.friction = 0
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
            sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
            sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
            moveGameplayNode(sprite, to: CGPoint(x: position.x + cos(angle) * 25, y: position.y + sin(angle) * 25), duration: 0.5)
        }
    }
}
