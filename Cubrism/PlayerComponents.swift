//
//  PlayerShootComponent.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/11/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class PlayerShootComponent: GKComponent {
    var scene: GameScene!
    var playerNode: SKNode!
    var coordinate: CGPoint!
    var sprite = SKSpriteNode()
    var node = SKNode()
    var playerSprite = SKNode()
    var velocity = CGPoint()
    var lastShotTime: NSTimeInterval = 0
    var shotIsPending: Bool = false
    init(scene: GameScene, pNode: SKNode) {
        super.init()
        self.scene = scene
        self.playerNode = pNode
        self.playerSprite = self.playerNode.childNodeWithName("playerSprite")!
        //let joystick = AnalogJoystick(diameter: 100, colors: (UIColor(red: 255.0/255.0, green: 249.0/255.0, blue: 58.0/255.0, alpha: 0.8), UIColor(red: 20.0/255.0, green: 27.0/255.0, blue: 169.0/255.0, alpha: 0.8)))
        let joystick = AnalogJoystick(diameter: 100, colors: (UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 0.4), UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)))

        
        joystick.position = CGPointMake(scene.size.width - joystick.radius -  30, joystick.radius + 30)
        scene.addChild(joystick)
        joystick.startHandler = { [unowned self] in
            scene.started = true
        
        }
        joystick.trackingHandler = { [unowned scene] data in
            self.velocity = data.velocity
            if (scene.paused == false)
            {
                if (data.velocity.x > 10.0 || data.velocity.x < -10.0 || data.velocity.y > 10.0 || data.velocity.y < -10.0)
                {
                    self.velocity = data.velocity
                    let angle = Double(atan(Double(self.velocity.y)/Double(self.velocity.x)))
                    self.velocity.x = CGFloat(cos(angle) * 50.0)
                    self.velocity.y = CGFloat(sin(angle) * 50.0)
                    if (data.velocity.x < 0.0)
                    {
                        self.velocity.x = -self.velocity.x
                        self.velocity.y = -self.velocity.y
                    }
                    self.shotIsPending = true
                    self.ShotIfNeeded(scene.time)
                }
            }
        }
        
    }
    
    func ShotIfNeeded(currentTime: NSTimeInterval) {
        if shotIsPending && (lastShotTime + NSTimeInterval(Player.shotCoolDownSeconds) <= currentTime) {
            shotIsPending = false
            lastShotTime = currentTime
            self.fire(self.velocity)
        }
    }
    
    
    
    
    
    func fire(velocity: CGPoint)
    {
        self.sprite = SKSpriteNode(imageNamed: "playerShot")
        self.node = SKNode()
        self.node.position = self.playerSprite.position
        self.node.addChild(self.sprite)
        self.sprite.physicsBody = SKPhysicsBody(rectangleOfSize: self.sprite.size)
        self.sprite.physicsBody?.allowsRotation = false
        self.sprite.physicsBody?.affectedByGravity = false;
        self.sprite.physicsBody?.dynamic = true
        self.sprite.physicsBody?.friction = 0;
        self.sprite.physicsBody?.usesPreciseCollisionDetection = true
        self.sprite.physicsBody?.categoryBitMask = Constants.playerShotCategory
        self.sprite.physicsBody?.contactTestBitMask = Constants.enemyCategory | Constants.wallCategory | Constants.bossCategory
        self.sprite.physicsBody?.collisionBitMask = Constants.enemyCategory | Constants.wallCategory | Constants.bossCategory
        
        
        
//
//        self.sprite.physicsBody?.collisionBitMask = UInt32(32)
        scene.addChild(self.node)
        self.followPath(velocity)
    }

    func followPath(velocity: CGPoint) {
        var sequence = [SKAction]()
        let destination = CGPoint(x:Int(20.0*velocity.x), y:Int(20.0*velocity.y))
        let action = SKAction.sequence([SKAction.moveTo(destination, duration: 1.5), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sequence += [action]
        
        self.sprite.runAction(SKAction.sequence(sequence))
    }
    
}

class PlayerMovementComponent: GKComponent {
    var scene: GameScene!
    var node: SKNode!
    var coordinate: CGPoint!
    var playerSprite: SKSpriteNode!
    init(scene: GameScene, node: SKNode, sprite:SKSpriteNode) {
        super.init()
        self.scene = scene
        self.node = node
        playerSprite = sprite
        self.coordinate = self.node.position
        //let joystick = AnalogJoystick(diameter: 100, colors: (UIColor(red: 20.0/255.0, green: 27.0/255.0, blue: 169.0/255.0, alpha: 0.3), UIColor(red: 255.0/255.0, green: 249.0/255.0, blue: 58.0/255.0, alpha: 0.8)))
        let joystick = AnalogJoystick(diameter: 100, colors: (UIColor(red: 50.0/255.0, green: 50.0/255.0, blue: 50.0/255.0, alpha: 0.4), UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)))
        
        joystick.position = CGPointMake(joystick.radius + 30, joystick.radius + 30)
        scene.addChild(joystick)
        joystick.startHandler = { [unowned self] in
            scene.started = true
            
        }
        joystick.trackingHandler = { [unowned scene] data in
            
            if (scene.paused == false)
            {
            self.playerSprite.position = CGPointMake(self.playerSprite.position.x + (data.velocity.x * 0.15), self.playerSprite.position.y + (data.velocity.y * 0.15))
            }
        }
        
        
    }
    
}

class ExpBarComponent: GKComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var healthBar = SKCropNode()
    let expNode = SKNode()
    var expCropSprite: SKSpriteNode!
    var expBackgroundSprite: SKSpriteNode!
    var levelLabel:UILabel!
    init(scene: GameScene) {
        let totalHeight = scene.size.height * 0.04
        expBackgroundSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarBottom"), size: CGSizeMake(CGFloat(scene.size.width * 0.25), totalHeight))
        expCropSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarTop"), size: CGSizeMake(CGFloat(scene.size.width * 0.25),totalHeight ))
        expCropSprite.zPosition = (expBackgroundSprite.zPosition + 1)
        expNode.addChild(expBackgroundSprite)
        expNode.addChild(expCropSprite)
        expNode.position = CGPointMake(scene.size.width * 0.05, scene.size.height - scene.size.height * 0.07)
        expBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        expCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(expNode)
        self.scene = scene
        
        levelLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0, y: scene.size.height * 0.025), size: CGSize(width: scene.frame.width * 0.045, height: scene.frame.height * 0.05)))
        levelLabel.font = UIFont(name: "Copperplate-Bold", size: 24)
        levelLabel.textColor = UIColor.whiteColor()
        levelLabel.text = String(format: "%i", Player.level)
        levelLabel.textAlignment = .Right
        scene.view!.addSubview(levelLabel)
        super.init()
        self.updateBars(Player.exp)
    }
    
    func updateBars(exp: Int)
    {
        expCropSprite.size.width = CGFloat(scene.size.width * 0.25 * CGFloat(Double(exp)/Double(Player.expToLevel(Player.level))))
        levelLabel.text = String(format: "%i", Player.level)
    }
}
