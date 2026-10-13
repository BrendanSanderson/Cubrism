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

    func restoreGameplayMotion(_ state: DelveMotionState, on node: SKNode) throws {
        try state.validate()
        guard !state.expired, liveMotions[state.id] == nil else { throw DelveError.invalidValue("live motion") }
        node.removeAllActions()
        node.position = state.movement.position.cgPoint
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
