//
//  DoorEntity.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/9/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameKit
import SpriteKit

class DoorEntity: GKEntity {
    var pointer = CGPoint()
    var node = SKNode()
    var position = CGPoint()
    var direction = Int()
    var type = String()
    var sprite = SKSpriteNode()
    init(scene: GameScene, direction: Int, type:String)
    {
        super.init()
        
        var imageName = "verticalDoor"
        var name = "door1"
        self.type = type
        var position = CGPoint(x: scene.size.width/2, y: (scene.size.height * 0.9 + 16))
        if (direction == 0)
        {
            position = CGPoint(x: scene.size.width/2, y: (scene.size.height * 0.9 + 16))
            imageName = "horizontalDoor"
            name = "door0"
        }
        else if (direction == 1)
        {
            let x = scene.size.width * 0.95 + 16
            position = CGPoint(x: x, y: scene.size.height/2)
            imageName = "verticalDoor"
            name = "door1"
        }
        else if (direction == 2)
        {
            position = CGPoint(x: scene.size.width/2, y: (scene.size.height * 0.1 - 16))
            imageName = "horizontalDoor"
            name = "door2"
        }
        else if (direction == 3)
        {
            let x = scene.size.width * 0.05 - 16
            position = CGPoint(x: x, y: scene.size.height/2)
            imageName = "verticalDoor"
            name = "door3"
        }
        if (type == "challenge")
        {
            imageName.appendContentsOf("Lock")
        }
        else if (type == "completed")
        {
            imageName.appendContentsOf("Unlock")
        }
        else if (type == "bossChallenge")
        {
            imageName.appendContentsOf("BossLock")
        }
        else if (type == "bossCompleted")
        {
            imageName.appendContentsOf("BossUnlock")
        }
        
        self.direction = direction
        let sprite = SKSpriteNode(imageNamed: imageName)
        node = SKNode();
        self.position = position
        node.position = position
        node.name = name
        self.sprite = sprite
        addComponent(VisualComponent(scene: scene, sprite: sprite))
        sprite.physicsBody?.dynamic = false
        if(type != "challenge" && type != "bossChallenge")
        {
            sprite.physicsBody?.categoryBitMask = Constants.doorCategory
        }
        
        node.addChild(sprite)

    }
    
}
