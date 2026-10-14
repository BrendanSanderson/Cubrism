import SpriteKit

enum DelveSpriteBridge {
    static func id(_ node: SKNode) -> UUID {
        if let value = node.userData?["delveNodeID"] as? String, let id = UUID(uuidString: value) { return id }
        let id = UUID()
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["delveNodeID"] = id.uuidString
        return id
    }

    static func assignID(_ id: UUID, to node: SKNode) {
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["delveNodeID"] = id.uuidString
    }

    static func pose(_ sprite: SKSpriteNode) -> DelvePose {
        DelvePose(position: point(sprite.position), width: Double(sprite.size.width), height: Double(sprite.size.height),
                  rotation: Double(sprite.zRotation), scaleX: Double(sprite.xScale), scaleY: Double(sprite.yScale),
                  z: Double(sprite.zPosition), alpha: Double(sprite.alpha))
    }

    static func apply(_ pose: DelvePose, to sprite: SKSpriteNode) throws {
        try pose.validate()
        sprite.position = cgPoint(pose.position)
        sprite.size = CGSize(width: pose.width, height: pose.height)
        sprite.zRotation = CGFloat(pose.rotation)
        sprite.xScale = CGFloat(pose.scaleX)
        sprite.yScale = CGFloat(pose.scaleY)
        sprite.zPosition = CGFloat(pose.z)
        sprite.alpha = CGFloat(pose.alpha)
    }

    static func body(_ body: SKPhysicsBody?) -> DelveBodyState? {
        guard let body = body else { return nil }
        return DelveBodyState(category: body.categoryBitMask, collision: body.collisionBitMask,
            contact: body.contactTestBitMask, dynamic: body.isDynamic, allowsRotation: body.allowsRotation,
            gravity: body.affectedByGravity, precise: body.usesPreciseCollisionDetection,
            velocity: DelvePoint(x: Double(body.velocity.dx), y: Double(body.velocity.dy)),
            angularVelocity: Double(body.angularVelocity), mass: Double(body.mass), friction: Double(body.friction),
            restitution: Double(body.restitution), linearDamping: Double(body.linearDamping), angularDamping: Double(body.angularDamping))
    }

    static func apply(_ state: DelveBodyState?, to sprite: SKSpriteNode) throws {
        guard let state = state else { sprite.physicsBody = nil; return }
        try state.validate()
        let body = SKPhysicsBody(rectangleOf: sprite.size)
        body.categoryBitMask = state.category
        body.collisionBitMask = state.collision
        body.contactTestBitMask = state.contact
        body.isDynamic = state.dynamic
        body.allowsRotation = state.allowsRotation
        body.affectedByGravity = state.gravity
        body.usesPreciseCollisionDetection = state.precise
        body.velocity = CGVector(dx: state.velocity.x, dy: state.velocity.y)
        body.angularVelocity = CGFloat(state.angularVelocity)
        body.mass = CGFloat(state.mass)
        body.friction = CGFloat(state.friction)
        body.restitution = CGFloat(state.restitution)
        body.linearDamping = CGFloat(state.linearDamping)
        body.angularDamping = CGFloat(state.angularDamping)
        sprite.physicsBody = body
    }

    static func point(_ point: CGPoint) -> DelvePoint { DelvePoint(x: Double(point.x), y: Double(point.y)) }
    static func cgPoint(_ point: DelvePoint) -> CGPoint { CGPoint(x: point.x, y: point.y) }
}
