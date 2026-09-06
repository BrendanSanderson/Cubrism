//
//  KeyboardControlState.swift
//  Cubrism
//
//  Created by Codex on 7/2/26.
//

import CoreGraphics

struct KeyboardControlState {
    enum Key {
        case w
        case a
        case s
        case d
        case up
        case down
        case left
        case right
    }

    static let velocity: CGFloat = 50.0

    private var pressedKeys = Set<Key>()
    private var pendingKeys = Set<Key>()

    var movementVelocity: CGPoint {
        return velocityFor(left: .a, right: .d, up: .w, down: .s)
    }

    var shootingVelocity: CGPoint {
        return velocityFor(left: .left, right: .right, up: .up, down: .down)
    }

    var isMoving: Bool {
        return movementVelocity != .zero
    }

    var isShooting: Bool {
        return shootingVelocity != .zero
    }

    mutating func press(_ key: Key) {
        pressedKeys.insert(key)
        pendingKeys.insert(key)
    }

    mutating func release(_ key: Key) {
        pressedKeys.remove(key)
    }

    /// Keep very short taps until one game frame has consumed them.
    mutating func finishFrame() {
        pendingKeys.removeAll()
    }

    mutating func reset() {
        pressedKeys.removeAll()
        pendingKeys.removeAll()
    }

    private func velocityFor(left: Key, right: Key, up: Key, down: Key) -> CGPoint {
        let x = axis(negative: left, positive: right)
        let y = axis(negative: down, positive: up)

        if x == 0 && y == 0 {
            return .zero
        }

        let length = sqrt((x * x) + (y * y))
        return CGPoint(
            x: CGFloat(x / length) * KeyboardControlState.velocity,
            y: CGFloat(y / length) * KeyboardControlState.velocity
        )
    }

    private func axis(negative: Key, positive: Key) -> Double {
        var value = 0.0
        if pressedKeys.contains(negative) || pendingKeys.contains(negative) {
            value -= 1.0
        }
        if pressedKeys.contains(positive) || pendingKeys.contains(positive) {
            value += 1.0
        }
        return value
    }
}
