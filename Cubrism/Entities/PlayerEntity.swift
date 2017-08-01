//
//  PlayerEntity.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/6/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit

class PlayerEntity: DynamicEntity {
    let playerCategory: UInt32 = 0x1 << 0
    var node = SKNode()
    var sprite = SKSpriteNode()
    var lastHit = TimeInterval(0)
    var cannonSprite = SKSpriteNode()
    var shooting = false
    var moving = true
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
        cannonSprite = SKSpriteNode (imageNamed: "playerCannon")
        sprite.name = "playerSprite"
        sprite.position = position
        sprite.zPosition = 100
        cannonSprite.zPosition = 101
        cannonSprite.zRotation = CGFloat(Double.pi/2.0)
        node.addChild(sprite)
        sprite.addChild(cannonSprite)
        addComponent(VisualComponent(scene: scene, sprite: sprite))
        addComponent(PlayerMovementComponent(scene: scene, node: node, sprite: sprite))
        addComponent(PlayerShootComponent(scene: scene, pNode: node))
        if (scene.isKind(of: HomeScene.self))
        {
            addComponent(ExpBarComponent(scene: scene))
        }
        else
        {
            addComponent(HealthBarComponent(scene: scene, playerNode: node, sprite: sprite))
        }
        sprite.physicsBody?.isDynamic = true
        
        sprite.physicsBody?.categoryBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.doorCategory | Constants.wallCategory | Constants.enemyCategory | Constants.bossCategory | Constants.enemyShotCategory
        
        sprite.physicsBody?.contactTestBitMask = Constants.doorCategory | Constants.enemyShotCategory | Constants.enemyCategory | Constants.bossCategory | Constants.wallCategory | Constants.enemyStatusShotCategory
        scene.addChild(node)
        lastHit = scene.time
    }
    override init()
    {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
