//
//  VisualComponent.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/6/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit

class VisualComponent: ActionComponent {
    var scene: GameScene!
    var sprite: SKSpriteNode!
    var coordinate: CGPoint!
    
    init(scene: GameScene, sprite: SKSpriteNode) {
        self.scene = scene
        self.sprite = sprite
        self.coordinate = self.sprite.position
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false;
        sprite.physicsBody?.friction = 0;
        sprite.physicsBody?.usesPreciseCollisionDetection = true
    }

}
