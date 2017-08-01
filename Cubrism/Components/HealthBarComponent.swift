//
//  HealthBarComponent.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/12/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit


class HealthBarComponent: GKComponent {
    var scene: GameScene!
    var coordinate: CGPoint!
    var playerSprite: SKSpriteNode!
    var healthBar = SKCropNode()
    let healthNode = SKNode()
    let shieldNode = SKNode()
    var shieldCropSprite = SKSpriteNode()
    var healthCropSprite = SKSpriteNode()
    init(scene: GameScene, playerNode: SKNode, sprite:SKSpriteNode) {
        let totalHeight = scene.size.height * 0.08
        let healthBackgroundSprite = SKSpriteNode(texture: SKTexture(imageNamed: "healthBarBottom"), size: CGSize(width: CGFloat(scene.size.width * 0.25), height: totalHeight))
        healthCropSprite = SKSpriteNode(texture: SKTexture(imageNamed: "healthBarTop"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight ))
        healthCropSprite.zPosition = (healthBackgroundSprite.zPosition + 1)
        healthNode.addChild(healthBackgroundSprite)
        healthNode.addChild(healthCropSprite)
        healthNode.position = CGPoint(x: scene.size.width * 0.05, y: scene.size.height - scene.size.height * 0.09)
        healthBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        healthCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(healthNode)
        self.scene = scene
        shieldCropSprite = SKSpriteNode(texture: SKTexture(imageNamed: "shieldBarTop"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight))
        let shieldBackgroundSprite = SKSpriteNode(texture: SKTexture(imageNamed: "shieldBarBottom"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight))
        shieldNode.addChild(shieldBackgroundSprite)
        shieldNode.addChild(shieldCropSprite)
        shieldCropSprite.zPosition = (shieldBackgroundSprite.zPosition + 1)
        shieldNode.position = CGPoint(x: scene.size.width * 0.05, y: scene.size.height - shieldBackgroundSprite.frame.height)
        shieldBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        shieldCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(shieldNode)
        
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBars(_ shield: Double, health: Double)
    {
        shieldCropSprite.size.width = CGFloat(scene.size.width * 0.25 * (CGFloat(shield)/CGFloat(Player.shield)))
        healthCropSprite.size.width = CGFloat(scene.size.width * 0.25 * CGFloat(Double(health)/Double(Player.health)))
    }
    
}
