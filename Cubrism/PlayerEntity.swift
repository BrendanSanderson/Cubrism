//
//  PlayerEntity.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/6/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit

class PlayerEntity: DynamicEntity {
    let playerCategory: UInt32 = 0x1 << 0
    var node = SKNode()
    var sprite = SKSpriteNode()
    var lastHit = NSTimeInterval(0)
    
    convenience init(scene: GameScene)
    {
        
        let centerPosition = CGPoint(
            x: scene.size.width/2,
            y: scene.size.height/2)
        self.init(scene: scene, position: centerPosition)
        
    }
    
    init(scene: GameScene, position: CGPoint)
    {
        super.init()
        
        sprite = SKSpriteNode (imageNamed: "playerIcon")
        sprite.name = "playerSprite"
        sprite.position = position
        sprite.zPosition = 100
        node.addChild(sprite)
        addComponent(VisualComponent(scene: scene, sprite: sprite))
        addComponent(PlayerMovementComponent(scene: scene, node: node, sprite: sprite))
        addComponent(PlayerShootComponent(scene: scene, pNode: node))
        if (scene.isKindOfClass(HomeScene))
        {
            addComponent(ExpBarComponent(scene: scene))
        }
        else
        {
            addComponent(HealthBarComponent(scene: scene, playerNode: node, sprite: sprite))
        }
        sprite.physicsBody?.dynamic = true
        
        sprite.physicsBody?.categoryBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.doorCategory | Constants.wallCategory | Constants.enemyCategory | Constants.bossCategory | Constants.enemyShotCategory
        
        sprite.physicsBody?.contactTestBitMask = Constants.doorCategory | Constants.enemyShotCategory | Constants.enemyCategory | Constants.bossCategory | Constants.wallCategory | Constants.enemyShotCategory
        scene.addChild(node)
        lastHit = scene.time
    }
    override init()
    {
        super.init()
    }


}
