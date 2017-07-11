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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class BossSprayComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shots = 0
    var shooter: BossEntity!
    var lastShot: TimeInterval = 0
    var angle = 0.0
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        super.init()
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
        if (acting == false)
        {
            acting = true
            shots = 0
            angle =  2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)
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
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
        sprite.position = bossSprite.position
        
        
        scene.addChild(node)
        self.followPath(sprite)
        
    }
    
    func followPath(_ sprite: SKSpriteNode)
    {
        var moveTo = CGPoint()
        moveTo.x = CGFloat(cos(angle) * 500.0)
        moveTo.y = CGFloat(sin(angle) * 500.0)
        let action = SKAction.sequence([SKAction.move(to: CGPoint(x: (sprite.position.x + moveTo.x), y: (sprite.position.y + moveTo.y)), duration: 2), SKAction.wait(forDuration: 3.0/60.0), SKAction.removeFromParent()])
        
        sprite.run(action)
        if (shots < 16)
        {
            angle += Double.pi/4.0 * 0.5
        }
        else if (shots < 32)
        {
            angle -= Double.pi/4.0 * 0.5
        }
        shots += 1
    }
    
}

class BossElectricFieldComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shooter: BossEntity!
    var lastShot: TimeInterval = 0
    var points = [CGPoint]()
    var node = ShotNode()
    var exploded = false
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        super.init()
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
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
    
    func followPath(_ sprite: SKSpriteNode, point: CGPoint)
    {
        let action = SKAction.sequence([SKAction.move(to: point, duration: 2), SKAction.wait(forDuration: 3.0/60.0), SKAction.removeFromParent()])
        sprite.run(action)
        
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
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.friction = 0
            sprite.physicsBody?.usesPreciseCollisionDetection = true
            sprite.physicsBody?.categoryBitMask = Constants.enemyStatusShotCategory
            sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
            sprite.physicsBody?.collisionBitMask = Constants.wallCategory
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
    let shotCooldownSeconds: TimeInterval = 1
    var image: String!
    
    var lastShotTime: TimeInterval = 0
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func action(_ currentTime: TimeInterval)
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
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.isDynamic = true
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
    
    func followPath(_ sprite: SKSpriteNode)
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
        let action = SKAction.sequence([SKAction.move(to: CGPoint(x: (enemySprite.position.x + moveTo.x), y: (enemySprite.position.y + moveTo.y)), duration: 4), SKAction.wait(forDuration: 3.0/60.0), SKAction.removeFromParent()])
        
        sequence += [action]
        
        sprite.run(SKAction.sequence(sequence))
    }
    
}

class BossDragonBreatheComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shots = 0
    var shooter: BossEntity!
    var lastShot: TimeInterval = 0
    var shotStart: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var dragonMouthOpen = [SKTexture]()
    var dragonMouthClose = [SKTexture]()
    var nodes = [SKNode]()
    init(scene: GameScene, sprite: SKSpriteNode, entity:BossEntity) {
        super.init()
        self.scene = scene
        self.bossSprite = sprite
        shooter = entity
        for i in 0 ..< 4
        {
            dragonMouthOpen.append(SKTexture(imageNamed: "dragonMouth\(i+1)"))
            dragonMouthClose.insert(SKTexture(imageNamed: "dragonMouth\(i+1)"), at: 0)
        }
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
        self.currentTime = currentTime
        if (acting == false)
        {
            acting = true
            shots = 0
            shotStart = currentTime
            bossSprite.zRotation = 0
            bossSprite.run(SKAction.animate(with: dragonMouthOpen, timePerFrame: 0.125))
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
            bossSprite.run(SKAction.animate(with: dragonMouthClose, timePerFrame: 0.125))
            acting = false
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.bossShooter = shooter
        node.type = "DragonBreathe"
        let sprite = SKSpriteNode(imageNamed: String(format: "bossDragonShot%i", Int(arc4random_uniform(UInt32(4)))))
        node.addChild(sprite)
        node.zPosition = shooter.node.zPosition - 1
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.isDynamic = true
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
    
    func followPath(_ sprite: SKSpriteNode)
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
            moveTo.y = (CGFloat(arc4random()).truncatingRemainder(dividingBy: scene.size.height) * 0.1) + scene.size.height * 0.45
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
            moveTo.y = (CGFloat(arc4random()).truncatingRemainder(dividingBy: scene.size.height) * 0.9) + scene.size.height * 0.05
        }
        let action = SKAction.sequence([SKAction.move(to: moveTo, duration: 0.5), SKAction.wait(forDuration: 3.0/60.0), SKAction.removeFromParent()])
        let action1 = SKAction.sequence([SKAction.wait(forDuration: 0.75), SKAction.removeFromParent()])
        
        sprite.run(action)
        sprite.parent?.run(action1)
        shots += 1
    }
    
}
class BossDragonFireballComponent: ActionComponent {
    var scene: GameScene!
    var bossSprite: SKSpriteNode!
    var shooter: BossEntity!
    var lastShot: TimeInterval = 0
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
            dragonMouthClose.insert(SKTexture(imageNamed: "dragonMouth\(i+1)"), at: 0)
        }
        super.init()
        let action1 = (SKAction.animate(with: dragonMouthOpen, timePerFrame: 0.125))
        let action2 = SKAction.run({self.fire()})
        let action3 = (SKAction.animate(with: dragonMouthClose, timePerFrame: 0.125))
        shootFireBall = SKAction.sequence([action1, action2, action3])
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
        if (acting == false)
        {
            acting = true
            lastShot = currentTime
            bossSprite.run(shootFireBall)
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
        super.init()
        self.scene = scene
        self.bossSprite = entity.sprite
        self.bossEntity = entity
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
        if (bossEntity.attack == nil || bossEntity.attack.isKind(of: BossDragonBreatheComponent.self) == false || bossEntity.attack.acting != true)
        {
            if (bossSprite.position.x < scene.size.width * 0.5)
            {
                var rotateAngle = atan2(Double(Player.entity.sprite.position.y - bossSprite.position.y), Double(Player.entity.sprite.position.x - bossSprite.position.x))
                if (rotateAngle >= Double.pi/6.0)
                {
                    rotateAngle = Double.pi/6.0
                }
                else if (rotateAngle <= -Double.pi/6.0)
                {
                    rotateAngle = -Double.pi/6.0
                }
                bossSprite.zRotation = CGFloat(rotateAngle)
            }
            else
            {
            
                var rotateAngle = atan2(Double(bossSprite.position.y - Player.entity.sprite.position.y), Double(bossSprite.position.x - Player.entity.sprite.position.x))
                if (rotateAngle >= Double.pi/6.0)
                {
                    rotateAngle = Double.pi/6.0
                }
                else if (rotateAngle <= -Double.pi/6.0)
                {
                    rotateAngle = -Double.pi/6.0
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
    var lastJump = TimeInterval(0)
    var lastMoveJump = TimeInterval(0)
    var moves = 0
    var direction = 0
    init(scene: GameScene, entity: BossEntity) {
        super.init()
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
                golemJumpDown.insert(SKTexture(imageNamed: "golemJump\(i)"), at: 0)
            }
        }
        //let action1 = (SKAction.animateWithTextures(golemJumpUp, timePerFrame: 0.09))
        //let action2 = (SKAction.animateWithTextures(golemJumpDown, timePerFrame: 0.09))
        //golemJump = SKAction.sequence([action1, action2])
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
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
    var lastShot: TimeInterval = 0
    var angle = [CGFloat]()
    var velocity = [CGFloat]()
    var sprites = [SKSpriteNode]()
    var startTime: TimeInterval = 0
    
    init(scene: GameScene, entity:BossEntity) {
        super.init()
        self.scene = scene
        self.bossSprite = entity.sprite
        shooter = entity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
        if (acting == false)
        {
            acting = true
            shots = 0
            startTime = currentTime
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
            self.angle.append(CGFloat(2.0 * Double.pi * (Double(arc4random()) / 0xFFFFFFFF)))
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
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.isDynamic = false
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory
        
        sprite.position = bossSprite.position
        
        sprites.append(sprite)
        scene.addChild(node)
        
    }
    
    func followPath(_ sprite: SKSpriteNode, shotNum: Int)
    {
        if (sprite.position.x + sprite.size.width/2 >= (0.95) * Constants.w || sprite.position.x - sprite.size.width/2 <= (0.05) * Constants.w)
        {
            if (cos(angle[shotNum]) >= 0 && sprite.position.x + sprite.size.width/2 >= (0.95)*Constants.w)
            {
                let temp = angle[shotNum]
                angle[shotNum] = CGFloat(Double.pi)-temp
            }
            else if (cos(angle[shotNum]) <= 0 &&  sprite.position.x - sprite.size.width/2 <= (0.05)*Constants.w)
            {
                let temp = angle[shotNum]
                angle[shotNum] = CGFloat(Double.pi)-temp
                
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval)
    {
        
        if (bossSprite.physicsBody?.allContactedBodies().count > 0)
        {
            if (bossSprite.physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
            {
                if(Player.entity.lastHit + 0.5 <= currentTime)
                {
                    Player.damagePlayer(Double((bossSprite.parent as! BossNode).Entity.meleeAttackPower))
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
    var lastShot: TimeInterval = 0
    var points = [CGPoint]()
    var node = ShotNode()
    var landed = false
    var lastChange = TimeInterval(0)
    init(scene: GameScene, entity:BossEntity) {
        super.init()
        self.scene = scene
        self.bossSprite = entity.sprite
        shooter = entity
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func action(_ currentTime: TimeInterval) {
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
            let sprite = SKSpriteNode(color: UIColor.black, size: Player.entity.sprite.size)
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
            
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.allowsRotation = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.isDynamic = false
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
        healthBackgroundSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarBottom"), size: CGSize(width: CGFloat(scene.size.width * 0.25), height: totalHeight))
        healthCropSprite = SKSpriteNode(texture: SKTexture(imageNamed: "bossBarTop"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight ))
        healthCropSprite.zPosition = (healthBackgroundSprite.zPosition + 1)
        healthNode.addChild(healthBackgroundSprite)
        healthNode.addChild(healthCropSprite)
        healthNode.position = CGPoint(x: scene.size.width * 0.7, y: scene.size.height - scene.size.height * 0.07)
        healthBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        healthCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(healthNode)
        self.scene = scene
        
        super.init()
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBars(_ health: Double, totalHealth: Double)
    {
        healthCropSprite.size.width = CGFloat(scene.size.width * 0.25 * CGFloat(Double(health)/Double(totalHealth)))
        if (health <= 0)
        {
            healthCropSprite.removeFromParent()
            healthBackgroundSprite.removeFromParent()
        }
    }
    
}
