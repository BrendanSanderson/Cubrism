//
//  BossComponents.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/19/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class BossSprayComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shots = 0
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var angle = 0.0
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
    }
    override func action(currentTime: NSTimeInterval) {
        if (acting == false)
        {
            acting = true
            shots = 0
            angle =  2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)
        }
        else if (lastShot + 0.1 <= currentTime && shots < 32)
        {
            self.fire()
            lastShot = currentTime
            
        }
        else if (shots >= 32)
        {
            acting = false
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.bossShooter = shooter
        let sprite = SKSpriteNode(imageNamed: "bossGeneratorShot")
        node.addChild(sprite)
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
        sprite.position = bossSprite.position
        
        
        scene.addChild(node)
        self.followPath(sprite)
        
    }
    
    func followPath(sprite: SKSpriteNode)
    {
        var moveTo = CGPoint()
        moveTo.x = CGFloat(cos(angle) * 500.0)
        moveTo.y = CGFloat(sin(angle) * 500.0)
        let action = SKAction.sequence([SKAction.moveTo(CGPoint(x: (sprite.position.x + moveTo.x), y: (sprite.position.y + moveTo.y)), duration: 2), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sprite.runAction(action)
        if (shots < 16)
        {
            angle += M_PI_4 * 0.5
        }
        else if (shots < 32)
        {
            angle -= M_PI_4 * 0.5
        }
        shots += 1
    }
    
}

class BossElectricFieldComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var points = [CGPoint]()
    var node = ShotNode()
    var exploded = false
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
    }
    override func action(currentTime: NSTimeInterval) {
        if (acting == false)
        {
            acting = true
            exploded = false
            for _ in 0 ..< 36
            {
                var finding = false
                while (finding == false)
                {
                    let x = Int(arc4random_uniform(UInt32(scene.frame.width*0.9 - Player.entity.sprite.size.width))) + Int(scene.frame.width*0.05 + Player.entity.sprite.size.width)
                    let y = Int(arc4random_uniform(UInt32(scene.frame.height*0.8 - Player.entity.sprite.size.height))) + Int(scene.frame.height*0.1 + Player.entity.sprite.size.height)
                    let distance = hypotf(abs(Float(bossSprite.position.x) - Float(x)), abs(Float(bossSprite.position.y) - Float(y)))
                    if (distance > 100)
                    {
                        points.append(CGPoint(x: x, y: y))
                        finding = true
                    }
                }

            }
            lastShot = currentTime
            self.fire()
        }
        else if lastShot + 2 <= currentTime && exploded == false
        {
            exploded = true
            self.explode()
        }
        else if lastShot + 2 <= currentTime && exploded == true && lastShot + 5 >= currentTime
        {
            for i in 0 ..< node.children.count
            {
                if (node.children[i].physicsBody?.allContactedBodies().count > 0)
                {
                    if (node.children[i].physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
                    {
                        if(Player.entity.lastHit + 0.2 <= currentTime)
                        {
                            Player.damagePlayer(Double(shooter.effectAttackPower))
                            Player.entity.lastHit = currentTime
                        }
                    }
                }
            }

        }
            
        else if (lastShot + 5 <= currentTime)
        {
            acting = false
            node.removeAllChildren()
            points.removeAll()
            
        }
        
    }
    func fire()
    {
        node = ShotNode()
        node.bossShooter = shooter
        for i in 0 ..< points.count
        {
            let sprite = SKSpriteNode(imageNamed: "bossEnergyShot")
            node.addChild(sprite)
//            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
//            sprite.physicsBody?.allowsRotation = false
//            sprite.physicsBody?.affectedByGravity = false
//            sprite.physicsBody?.dynamic = true
//            sprite.physicsBody?.friction = 0
//            sprite.physicsBody?.usesPreciseCollisionDetection = true
//            sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
//            sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
//            sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
            sprite.position = bossSprite.position
            self.followPath(sprite, point: points[i])
        }
        scene.addChild(node)
        
    }
    
    func followPath(sprite: SKSpriteNode, point: CGPoint)
    {
        let action = SKAction.sequence([SKAction.moveTo(point, duration: 2), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        sprite.runAction(action)
        
    }
    func explode()
    {
        node = ShotNode()
        node.bossShooter = nil
        for i in 0 ..< points.count
        {
            let sprite = SKSpriteNode(imageNamed: "bossEnergy")
            sprite.position = points[i]
            node.addChild(sprite)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.dynamic = false
            sprite.physicsBody?.friction = 0
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
            sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
            sprite.physicsBody?.collisionBitMask = Constants.teleporterCategory
        }
        scene.addChild(node)

    }
    
}

class BossShotTargetingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moveTo = CGPoint()
    var moving = false
    var shooter = BossEntity()
    let shotCooldownSeconds: NSTimeInterval = 1
    var image: String!
    
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    
    init(scene: GameScene, entity: BossEntity, image: String) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        self.playerSprite = Player.entity.sprite
        lastShotTime = scene.time
        self.image = image
        
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (lastShotTime + shotCooldownSeconds <= currentTime) {
            lastShotTime = currentTime
            self.fire()
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.bossShooter = shooter
        node.zPosition = shooter.node.zPosition - 1
        //let sprite = SKSpriteNode(color: UIColor(red: 77.0/255.0, green: 135.0/255.0, blue: 14.0/255.0, alpha: 1), size: CGSize(width: 5, height: 5))
        let sprite = SKSpriteNode(imageNamed: self.image)
        node.addChild(sprite)
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
        sprite.position = enemySprite.position
        
        //
        //        self.sprite.physicsBody?.collisionBitMask = UInt32(32)
        scene.addChild(node)
        self.followPath(sprite)
        
    }
    
    func followPath(sprite: SKSpriteNode)
    {
        playerSprite = Player.entity.sprite
        var sequence = [SKAction]()
        let angle = Double(atan((playerSprite.position.y - enemySprite.position.y)/(playerSprite.position.x - enemySprite.position.x)))
        var moveTo = CGPoint()
        moveTo.x = CGFloat(cos(angle) * 1000.0)
        moveTo.y = CGFloat(sin(angle) * 1000.0)
        if (playerSprite.position.x - enemySprite.position.x < 0)
        {
            moveTo.x = 0 - CGFloat(cos(angle) * 1000.0)
            moveTo.y = 0 - CGFloat(sin(angle) * 1000.0)
        }
        //let distance = Double(hypotf(abs(Float(playerSprite.position.x) - Float(enemySprite.position.x)), abs(Float(playerSprite.position.y) - Float(enemySprite.position.y))))
        let action = SKAction.sequence([SKAction.moveTo(CGPoint(x: (enemySprite.position.x + moveTo.x), y: (enemySprite.position.y + moveTo.y)), duration: 4), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sequence += [action]
        
        sprite.runAction(SKAction.sequence(sequence))
    }
    
}

class BossDragonBreatheComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shots = 0
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var shotStart: NSTimeInterval = 0
    var currentTime: NSTimeInterval = 0
    var dragonMouthOpen = [SKTexture]()
    var dragonMouthClose = [SKTexture]()
    var nodes = [SKNode]()
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
        for i in 0 ..< 4
        {
            dragonMouthOpen.append(SKTexture(imageNamed: "dragonMouth\(i+1)"))
            dragonMouthClose.insert(SKTexture(imageNamed: "dragonMouth\(i+1)"), atIndex: 0)
        }
        
    }
    override func action(currentTime: NSTimeInterval) {
        self.currentTime = currentTime
        if (acting == false)
        {
            acting = true
            shots = 0
            shotStart = currentTime
            bossSprite.zRotation = 0
            bossSprite.runAction(SKAction.animateWithTextures(dragonMouthOpen, timePerFrame: 0.125))
        }
        else if (lastShot + 0.01 <= currentTime && shots < 5000)
        {
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            self.fire()
            
            lastShot = currentTime
            
        }
        else if (shots >= 5000)
        {
            bossSprite.runAction(SKAction.animateWithTextures(dragonMouthClose, timePerFrame: 0.125))
            acting = false
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.bossShooter = shooter
        node.type = "GolemRock"
        let sprite = SKSpriteNode(imageNamed: String(format: "bossDragonShot%i", Int(arc4random_uniform(UInt32(4)))))
        node.addChild(sprite)
        node.zPosition = shooter.node.zPosition - 1
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        if (shooter.sprite.position.x > scene.size.width/2)
        {
            sprite.position = CGPoint(x: scene.size.width - shooter.sprite.size.height * 2.0/2.5, y: scene.size.height/2)
        }
        
        else
        {
            sprite.position = CGPoint(x:shooter.sprite.size.width, y: scene.size.height/2)
        }
        scene.addChild(node)
        self.followPath(sprite)
        
    }
    
    func followPath(sprite: SKSpriteNode)
    {
        var moveTo = CGPoint()
        if (shotStart + 1 > currentTime)
        {
            if (shooter.sprite.position.x > scene.size.width/2)
            {
                moveTo.x = scene.size.width * 0.70
            }
            else
            {
                moveTo.x = scene.size.width * 0.30
            }
            moveTo.y = (CGFloat(arc4random()) % scene.size.height * 0.1) + scene.size.height * 0.45
        }
        else
        {
            if (shooter.sprite.position.x > scene.size.width/2)
            {
                moveTo.x = scene.size.width * 0.05
            }
            else
            {
                moveTo.x = scene.size.width * 0.95
            }
            moveTo.y = (CGFloat(arc4random()) % scene.size.height * 0.9) + scene.size.height * 0.05
        }
        let action = SKAction.sequence([SKAction.moveTo(moveTo, duration: 0.5), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sprite.runAction(action)
        shots += 1
    }
    
}
class BossDragonFireballComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var dragonMouthOpen = [SKTexture]()
    var dragonMouthClose = [SKTexture]()
    var shootFireBall: SKAction!
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
        for i in 0 ..< 4
        {
            dragonMouthOpen.append(SKTexture(imageNamed: "dragonMouth\(i+1)"))
            dragonMouthClose.insert(SKTexture(imageNamed: "dragonMouth\(i+1)"), atIndex: 0)
        }
        super.init()
        let action1 = (SKAction.animateWithTextures(dragonMouthOpen, timePerFrame: 0.125))
        let action2 = SKAction.runBlock({self.fire()})
        let action3 = (SKAction.animateWithTextures(dragonMouthClose, timePerFrame: 0.125))
        shootFireBall = SKAction.sequence([action1, action2, action3])
        
    }
    override func action(currentTime: NSTimeInterval) {
        if (acting == false)
        {
            acting = true
            lastShot = currentTime
            bossSprite.runAction(shootFireBall)
        }
        else if (lastShot + 5 <= currentTime)
        {
            acting = false
        }
        
    }
    func fire()
    {
        let shot = EnemyEntity(scene: scene, eType: "DragonFireball", lev: shooter.level, elite: false)
        shot.node.zPosition = shooter.node.zPosition - 1
        (scene as! RoomScene).entites.append(shot)
        
    }
    
}
class BossDragonHeadTilt: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var bossEntity: BossEntity!
    var bossHeight: CGFloat!
    init(scene: GameScene, entity: BossEntity) {
        self.scene = scene
        self.bossSprite = entity.sprite
        self.bossEntity = entity
        
    }
    override func action(currentTime: NSTimeInterval) {
        if (bossEntity.attack == nil || bossEntity.attack.isKindOfClass(BossDragonBreatheComponent) == false || bossEntity.attack.acting != true)
        {
            if (bossSprite.position.x < scene.size.width * 0.5)
            {
                var rotateAngle = atan2(Double(Player.entity.sprite.position.y - bossSprite.position.y), Double(Player.entity.sprite.position.x - bossSprite.position.x))
                if (rotateAngle >= M_PI/6.0)
                {
                    rotateAngle = M_PI/6.0
                }
                else if (rotateAngle <= -M_PI/6.0)
                {
                    rotateAngle = -M_PI/6.0
                }
                bossSprite.zRotation = CGFloat(rotateAngle)
            }
            else
            {
            
                var rotateAngle = atan2(Double(bossSprite.position.y - Player.entity.sprite.position.y), Double(bossSprite.position.x - Player.entity.sprite.position.x))
                if (rotateAngle >= M_PI/6.0)
                {
                    rotateAngle = M_PI/6.0
                }
                else if (rotateAngle <= -M_PI/6.0)
                {
                    rotateAngle = -M_PI/6.0
                }
                bossSprite.zRotation = CGFloat(rotateAngle)
            }
        }
    }
}

class BossGolemJumpComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var bossEntity: BossEntity!
    var golemJumpUp = [SKTexture]()
    var golemJumpDown = [SKTexture]()
    var golemJump: SKAction!
    var lastJump = NSTimeInterval(0)
    var lastMoveJump = NSTimeInterval(0)
    var moves = 0
    var direction = 0
    init(scene: GameScene, entity: BossEntity) {
        self.scene = scene
        self.bossSprite = entity.sprite
        self.bossEntity = entity
        for i in 0 ..< 9
        {
            if (i != 0)
            {
                golemJumpUp.append(SKTexture(imageNamed: "golemJump\(i)"))
            }
            if (i != 8)
            {
                golemJumpDown.insert(SKTexture(imageNamed: "golemJump\(i)"), atIndex: 0)
            }
        }
        //let action1 = (SKAction.animateWithTextures(golemJumpUp, timePerFrame: 0.09))
        //let action2 = (SKAction.animateWithTextures(golemJumpDown, timePerFrame: 0.09))
        //golemJump = SKAction.sequence([action1, action2])
        
    }
    override func action(currentTime: NSTimeInterval) {
//        if (bossEntity.attack == nil || bossEntity.attack.acting != true)
//        {
//        if (bossEntity.attack == nil || bossEntity.attack.acting != true)
//        {
            if (lastJump + 0.08 <= currentTime && moves == 0 && direction == 2)
            {
            //bossSprite.runAction(golemJump)
            lastJump = currentTime
            moves = 0
            direction = 0
            }
            else if (direction == 1)
            {
            if (lastMoveJump + 0.05) <= currentTime
            {
                //MOVE BOSS
                bossSprite.position = CGPoint(x: bossSprite.position.x, y: bossSprite.position.y - bossSprite.size.height * 0.02)
                bossSprite.texture = golemJumpDown[moves]
                moves += 1
            
                if moves == 8
                {
                    direction = 2
                    moves = 0
                }
                lastMoveJump = currentTime
            }
            }
        
            else if ( direction == 0)
            {
            if (lastMoveJump + 0.05) <= currentTime
            {
                //MOVE BOSS
                bossSprite.position = CGPoint(x: bossSprite.position.x, y: bossSprite.position.y + bossSprite.size.height * 0.02)
                bossSprite.texture = golemJumpUp[moves]
                moves += 1
              
                if moves == 8
                {
                    direction = 1
                    moves = 0
                }
                lastMoveJump = currentTime
            }
//            }
        }
        if Player.entity.sprite.position.x > bossSprite.position.x
        {
            bossSprite.xScale = 1
        }
        else
        {
            bossSprite.xScale = -1
        }
        
    }
}

class BossGolemRockShoot: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shots = 0
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var angle = [CGFloat]()
    var velocity = [CGFloat]()
    var sprites = [SKSpriteNode]()
    var startTime: NSTimeInterval = 0
    
    init(scene: GameScene, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = entity.sprite
        shooter = entity

        
    }
    override func action(currentTime: NSTimeInterval) {
        if (acting == false)
        {
            acting = true
            shots = 0
            startTime = currentTime
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * M_PI * (Double(arc4random()) / 0xFFFFFFFF)))
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
            self.velocity.append((CGFloat(arc4random_uniform(UInt32(16))) + 8.0)/4)
        }
        else if (lastShot + 0.2 <= currentTime && shots < 6)
        {
            self.fire()
            lastShot = currentTime
            self.followPath(sprites[0], shotNum: 0)
            if (shots >= 1)
            {
                self.followPath(sprites[1], shotNum: 1)
            }
            if (shots >= 2)
            {
                self.followPath(sprites[2], shotNum: 2)
            }
            if (shots >= 3)
            {
                self.followPath(sprites[3], shotNum: 3)
            }
            if (shots >= 4)
            {
                self.followPath(sprites[4], shotNum: 4)
            }
            if (shots >= 5)
            {
                self.followPath(sprites[5], shotNum: 5)
            }
            shots += 1
            
        }
        else if (shots < 6)
        {
            if (shots >= 1)
            {
                self.followPath(sprites[0], shotNum: 0)
            }
            if (shots >= 2)
            {
                self.followPath(sprites[1], shotNum: 1)
            }
            if (shots >= 3)
            {
                self.followPath(sprites[2], shotNum: 2)
            }
            if (shots >= 4)
            {
                self.followPath(sprites[3], shotNum: 3)
            }
            if (shots >= 5)
            {
                self.followPath(sprites[4], shotNum: 4)
            }
        }
        else if (shots >= 6)
        {
            self.followPath(sprites[0], shotNum: 0)
            self.followPath(sprites[1], shotNum: 1)
            self.followPath(sprites[2], shotNum: 2)
            self.followPath(sprites[3], shotNum: 3)
            self.followPath(sprites[4], shotNum: 4)
            self.followPath(sprites[5], shotNum: 5)
        }
        if (startTime + 5 <= currentTime)
        {
            sprites[0].parent?.removeFromParent()
            sprites[1].parent?.removeFromParent()
            sprites[2].parent?.removeFromParent()
            sprites[3].parent?.removeFromParent()
            sprites[4].parent?.removeFromParent()
            sprites[5].parent?.removeFromParent()
            self.angle.removeAll()
            self.velocity.removeAll()
            self.sprites.removeAll()
            acting = false
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.bossShooter = shooter
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossGolemRock"), size: Player.entity.sprite.size)
        node.addChild(sprite)
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = false
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory
        
        sprite.position = bossSprite.position
        
        sprites.append(sprite)
        scene.addChild(node)
        
    }
    
    func followPath(sprite: SKSpriteNode, shotNum: Int)
    {
        if (sprite.position.x + sprite.size.width/2 >= (0.95) * Constants.w || sprite.position.x - sprite.size.width/2 <= (0.05) * Constants.w)
        {
            if (cos(angle[shotNum]) >= 0 && sprite.position.x + sprite.size.width/2 >= (0.95)*Constants.w)
            {
                let temp = angle[shotNum]
                angle[shotNum] = CGFloat(M_PI)-temp
            }
            else if (cos(angle[shotNum]) <= 0 &&  sprite.position.x - sprite.size.width/2 <= (0.05)*Constants.w)
            {
                let temp = angle[shotNum]
                angle[shotNum] = CGFloat(M_PI)-temp
                
            }
        }

        
        if (sprite.position.y + sprite.size.height/2 >= (0.90) * Constants.h || sprite.position.y - sprite.size.height/2 <= (0.1) * Constants.h)
        {
            if (sin(angle[shotNum]) >= 0 && sprite.position.y + sprite.size.height/2 >= (0.90) * Constants.h)
            {
                let temp = angle[shotNum]
                angle[shotNum] = 0 - temp
            }
            else if (sin(angle[shotNum]) <= 0 && sprite.position.y - sprite.size.height/2 <= (0.1) * Constants.h)
            {
                let temp = angle[shotNum]
                angle[shotNum] = 0 - temp
                
            }
        }
        
        var moveTo = CGPoint()
        
        if (cos(angle[shotNum]) >= 0)
        {
            sprite.zRotation += CGFloat(velocity[shotNum]/sprite.size.width/2)
        }
        else
        {
            sprite.zRotation -= CGFloat(velocity[shotNum]/sprite.size.width/2)
        }
        
        moveTo.x = CGFloat(cos(angle[shotNum]) * velocity[shotNum])
        moveTo.y = CGFloat(sin(angle[shotNum]) * velocity[shotNum])
        
        
        
        sprite.position.x += moveTo.x
        sprite.position.y += moveTo.y
    }
    
}



class BossTrackingComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var coordinate: CGPoint!
    var moveSpeed = 2.5
    var bossEntity: BossEntity!
    init(scene: GameScene, entity: BossEntity, speed: Double) {
        super.init()
        self.scene = scene
        self.bossSprite = entity.sprite
        moveSpeed = speed
        self.coordinate = entity.sprite.position
        self.bossEntity = entity
        
    }
    override func action(currentTime: NSTimeInterval)
    {
        
        if (bossSprite.physicsBody?.allContactedBodies().count > 0)
        {
            if (bossSprite.physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
            {
                if(Player.entity.lastHit + 0.5 <= currentTime)
                {
                    Player.damagePlayer(Double((bossSprite.parent as! BossNode).entity.meleeAttackPower))
                    Player.entity.lastHit = currentTime
                }
            }
            
        }
        
//        if (bossEntity.attack == nil || bossEntity.attack.acting != true)
//        {
        let playerSprite = Player.entity.sprite
        let angle = abs(Double(atan(Double(playerSprite.position.y - bossSprite.position.y)/Double(playerSprite.position.x - bossSprite.position.x))))
        let moveX = abs(CGFloat(cos(angle) * moveSpeed))
        let moveY = abs(CGFloat(sin(angle) * moveSpeed))
        
        if (bossSprite.position.x < playerSprite.position.x)
        {
            bossSprite.position.x = bossSprite.position.x + moveX
        }
        else if (bossSprite.position.x > playerSprite.position.x)
        {
            bossSprite.position.x = bossSprite.position.x - moveX
        }
        
        if (bossSprite.position.y < playerSprite.position.y)
        {
            bossSprite.position.y = bossSprite.position.y + moveY
        }
        else if (bossSprite.position.y > playerSprite.position.y)
        {
            bossSprite.position.y = bossSprite.position.y - moveY
        }
//        }
    }
    
}


class GolemDropComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shooter: BossEntity!
    var lastShot: NSTimeInterval = 0
    var points = [CGPoint]()
    var node = ShotNode()
    var landed = false
    var lastChange = NSTimeInterval(0)
    init(scene: GameScene, entity:BossEntity) {
        self.scene = scene
        self.bossSprite = entity.sprite
        shooter = entity
    }
    override func action(currentTime: NSTimeInterval) {
        if (acting == false)
        {
            acting = true
            landed = false
            for _ in 0 ..< 36
            {
                var finding = false
                while (finding == false)
                {
                    let x = Int(arc4random_uniform(UInt32(scene.frame.width*0.9 - Player.entity.sprite.size.width))) + Int(scene.frame.width*0.05 + Player.entity.sprite.size.width)
                    let y = Int(arc4random_uniform(UInt32(scene.frame.height*0.8 - Player.entity.sprite.size.height))) + Int(scene.frame.height*0.1 + Player.entity.sprite.size.height)
                    let distance = hypotf(abs(Float(bossSprite.position.x) - Float(x)), abs(Float(bossSprite.position.y) - Float(y)))
                    if (distance > 100)
                    {
                        points.append(CGPoint(x: x, y: y))
                        finding = true
                    }
                }
                
            }
            lastShot = currentTime
            self.drop()
        }
        else if lastShot + 2 > currentTime && acting == true
        {
            if (lastChange + 0.04 <= currentTime)
            {
                for i in 0 ..< node.children.count
                {
                    (node.children[i] as? SKSpriteNode)!.alpha += 0.02
                }
                lastChange = currentTime
            }
        }
        else if lastShot + 2 <= currentTime && landed == false
        {
            node.removeFromParent()
            landed = true
            self.land()
        }
            
        else if lastShot + 2 <= currentTime && landed == true && lastShot + 5 >= currentTime
        {
//            for i in 0 ..< node.children.count
//            {
//                if (node.children[i].physicsBody?.allContactedBodies().count > 0)
//                {
//                    if (node.children[i].physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
//                    {
//                        if(Player.entity.lastHit + 0.2 <= currentTime)
//                        {
//                            Player.damagePlayer(Double(shooter.effectAttackPower))
//                            Player.entity.lastHit = currentTime
//                        }
//                    }
//                }
//            }
            
        }
            
        else if (lastShot + 5 <= currentTime)
        {
            acting = false
            node.removeAllChildren()
            points.removeAll()
            
        }
        
    }
    func drop()
    {
        node = ShotNode()
        node.bossShooter = shooter
        for i in 0 ..< points.count
        {
            let sprite = SKSpriteNode(color: UIColor.blackColor(), size: Player.entity.sprite.size)
            sprite.alpha = 0
            node.addChild(sprite)
            
            sprite.position = points[i]
        }
        scene.addChild(node)
        
    }
    
    func land()
    {
        node = ShotNode()
        node.bossShooter = nil
        for i in 0 ..< points.count
        {
            let sprite = SKSpriteNode(imageNamed: "golemBlock")
            sprite.position = points[i]
            sprite.zPosition = bossSprite.zPosition - 1
            node.addChild(sprite)
            
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.dynamic = false
            sprite.physicsBody?.friction = 0
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
            sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
            sprite.physicsBody?.collisionBitMask = Constants.playerCategory
        }
        scene.addChild(node)
        
        for i in 0 ..< node.children.count
        {
            if (node.children[i].physicsBody?.allContactedBodies().count > 0)
            {
                if (node.children[i].physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
                {
                    Player.damagePlayer(Double(shooter.effectAttackPower))
                }
            }
        }
        
    }
    
}


class BossBarComponent: GKComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var healthBar = SKCropNode()
    let healthNode = SKNode()
    var healthCropSprite: SKSpriteNode!
    var healthBackgroundSprite: SKSpriteNode!
    init(scene: GameScene) {
        let totalHeight = scene.size.height * 0.04
        healthBackgroundSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarBottom"), size: CGSizeMake(CGFloat(scene.size.width * 0.25), totalHeight))
        healthCropSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarTop"), size: CGSizeMake(CGFloat(scene.size.width * 0.25),totalHeight ))
        healthCropSprite.zPosition = (healthBackgroundSprite.zPosition + 1)
        healthNode.addChild(healthBackgroundSprite)
        healthNode.addChild(healthCropSprite)
        healthNode.position = CGPointMake(scene.size.width * 0.7, scene.size.height - scene.size.height * 0.07)
        healthBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        healthCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(healthNode)
        self.scene = scene
        
        super.init()
        
    }
    
    func updateBars(health: Double, totalHealth: Double)
    {
        healthCropSprite.size.width = CGFloat(scene.size.width * 0.25 * CGFloat(Double(health)/Double(totalHealth)))
        if (health <= 0)
        {
            healthCropSprite.removeFromParent()
            healthBackgroundSprite.removeFromParent()
        }
    }
    
}