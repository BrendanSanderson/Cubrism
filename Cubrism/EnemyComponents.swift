//
//  EnemyRandomMovement.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/13/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class EnemyRandomMovementComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moving = false
    var moveTo = CGPoint()
    var moveSpeed: Double = 1
    var distanceMultiplier = CGFloat(1)
    init(scene: GameScene, sprite: SKNode, speed: Double) {
        super.init()
        moveSpeed = speed
        self.scene = scene
        self.enemySprite = sprite
        self.coordinate = sprite.position
        
    }
    convenience init(scene: GameScene, sprite: SKNode, speed: Double, distanceMult: CGFloat) {
        self.init(scene: scene, sprite: sprite, speed: speed)
        distanceMultiplier = distanceMult
        
    }

    override func action(currentTime: NSTimeInterval)
    {
            if (moving == false)
            {
                moveTo.x = CGFloat(arc4random_uniform(UInt32((distanceMultiplier * scene.size.width * 0.9) - enemySprite.frame.width))) + ((1.0 -  (distanceMultiplier * 0.9))/2.0  * scene.size.width) + enemySprite.frame.width/2.0
            moveTo.y = CGFloat(arc4random_uniform(UInt32((distanceMultiplier * scene.size.height * 0.8) - enemySprite.frame.height))) + ((1.0 - (distanceMultiplier * 0.8))/2.0 * scene.size.height) + enemySprite.frame.height/2.0
                moving = true
            }
            let angle = abs(Double(atan(Double(moveTo.y - enemySprite.position.y)/Double(moveTo.x - enemySprite.position.x))))
            let moveX = abs(CGFloat(cos(angle) * moveSpeed))
            let moveY = abs(CGFloat(sin(angle) * moveSpeed))
            if (enemySprite.physicsBody?.allContactedBodies().count == 0)
            {

            if (Int(enemySprite.position.x) < Int(moveTo.x) - 3)
            {
                enemySprite.position.x = enemySprite.position.x + moveX
            }
            else if (Int(enemySprite.position.x) > Int(moveTo.x) + 3)
            {
                enemySprite.position.x = enemySprite.position.x - moveX
            }
            else
            {
                moving = false
            }
            if (Int(enemySprite.position.y) < Int(moveTo.y) - 3)
            {
                enemySprite.position.y = enemySprite.position.y + moveY
            }
            else if (Int(enemySprite.position.y) > Int(moveTo.y) + 3)
            {
                enemySprite.position.y = enemySprite.position.y - moveY
            }
            else
            {
                moving = false
            }
        }
    }

}



class EnemyTrackingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKSpriteNode!
    var coordinate: CGPoint!
    var moveSpeed = 2.5
    init(scene: GameScene, sprite: SKSpriteNode, speed: Double) {
        super.init()
        self.scene = scene
        self.enemySprite = sprite
        moveSpeed = speed
        self.coordinate = sprite.position
        
    }
    override func action(currentTime: NSTimeInterval)
    {
        if (enemySprite.physicsBody?.allContactedBodies().count > 0)
        {
            if (enemySprite.physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
            {
                if(Player.entity.lastHit + 0.5 <= currentTime)
                {
                    Player.damagePlayer(Double((enemySprite.parent as! EnemyNode).entity.meleeAttackPower))
                    Player.entity.lastHit = currentTime
                }
            }
        
        }
        let playerSprite = Player.entity.sprite
        let angle = abs(Double(atan(Double(playerSprite.position.y - enemySprite.position.y)/Double(playerSprite.position.x - enemySprite.position.x))))
        let moveX = abs(CGFloat(cos(angle) * moveSpeed))
        let moveY = abs(CGFloat(sin(angle) * moveSpeed))
        
        if (enemySprite.position.x < playerSprite.position.x)
        {
            enemySprite.position.x = enemySprite.position.x + moveX
        }
        else if (enemySprite.position.x > playerSprite.position.x)
        {
            enemySprite.position.x = enemySprite.position.x - moveX
        }
        
        if (enemySprite.position.y < playerSprite.position.y)
        {
            enemySprite.position.y = enemySprite.position.y + moveY
        }
        else if (enemySprite.position.y > playerSprite.position.y)
        {
            enemySprite.position.y = enemySprite.position.y - moveY
        }
    }
    
}



class EnemyShotTargetingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moveTo = CGPoint()
    var moving = false
    var shooter = EnemyEntity()
    let shotCooldownSeconds: NSTimeInterval = 1
    
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        self.playerSprite = Player.entity.sprite
        lastShotTime = scene.time
        
        
        
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
        node.shooter = shooter
        //let sprite = SKSpriteNode(color: UIColor(red: 77.0/255.0, green: 135.0/255.0, blue: 14.0/255.0, alpha: 1), size: CGSize(width: 5, height: 5))
        let sprite = SKSpriteNode(imageNamed: "enemyShot")
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
        moveTo.x = CGFloat(cos(angle) * 500.0)
        moveTo.y = CGFloat(sin(angle) * 500.0)
        if (playerSprite.position.x - enemySprite.position.x < 0)
        {
            moveTo.x = 0 - CGFloat(cos(angle) * 500.0)
            moveTo.y = 0 - CGFloat(sin(angle) * 500.0)
        }
        //let distance = Double(hypotf(abs(Float(playerSprite.position.x) - Float(enemySprite.position.x)), abs(Float(playerSprite.position.y) - Float(enemySprite.position.y))))
        let action = SKAction.sequence([SKAction.moveTo(CGPoint(x: (enemySprite.position.x + moveTo.x), y: (enemySprite.position.y + moveTo.y)), duration: 2), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sequence += [action]
        
        sprite.runAction(SKAction.sequence(sequence))
    }
    
}


class EnemyShotTrackingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moveTo = CGPoint()
    var moving = false
    var shooter = EnemyEntity()
    var bullet: SKSpriteNode!
    let shotLength: NSTimeInterval = 3
    let node = ShotNode()
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        node.shooter = shooter
        bullet = SKSpriteNode(imageNamed: "enemyTrackingShot")
        scene.addChild(node)
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (bullet.parent == nil) {
            self.fire()
            lastShotTime = currentTime
        }
        else if (lastShotTime + 5 >= currentTime)
        {
            self.followPath()
        }
        else
        {
            bullet.removeFromParent()
        }
    }
    func fire()
    {
        node.addChild(bullet)
        bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
        bullet.physicsBody?.allowsRotation = false
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.dynamic = true
        bullet.physicsBody?.friction = 0
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        bullet.physicsBody?.categoryBitMask = Constants.enemyTrackingShotCategory
        bullet.physicsBody?.contactTestBitMask = Constants.playerCategory
        bullet.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        bullet.position = enemySprite.position
    }
    func followPath()
    {
        let playerSprite = Player.entity.sprite
        let angle = abs(Double(atan(Double(playerSprite.position.y - bullet.position.y)/Double(playerSprite.position.x - bullet.position.x))))
        let moveX = abs(CGFloat(cos(angle) * 3))
        let moveY = abs(CGFloat(sin(angle) * 3))
        let rotateAngle = atan2(Double(playerSprite.position.y - bullet.position.y), Double(playerSprite.position.x - bullet.position.x))
        bullet.zRotation = CGFloat(rotateAngle)
//        else if (playerSprite.position.y - bullet.position.y > 0)
//        {
//            bullet.zRotation = CGFloat(3.14159 + angle)
//        }
//        else
//        {
//            bullet.zRotation = CGFloat(angle)
//        }
        
        if (bullet.position.x < playerSprite.position.x)
        {
            bullet.position.x = bullet.position.x + moveX
        }
        else
        {
            bullet.position.x = bullet.position.x - moveX
        }
        if (bullet.position.y < playerSprite.position.y)
        {
            bullet.position.y = bullet.position.y + moveY
        }
        else
        {
            bullet.position.y = bullet.position.y - moveY
        }
    }

    
}


class EnemyDashMovementComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moving = false
    var moveTo = CGPoint()
    var moveSpeed: Double = 1
    var finishedMove: NSTimeInterval = 0
    init(scene: GameScene, sprite: SKNode, speed: Double) {
        super.init()
        moveSpeed = speed
        self.scene = scene
        self.enemySprite = sprite
        self.coordinate = sprite.position
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (moving == false && finishedMove + 1 <= currentTime)
        {
            if (Player.entity.sprite.position.x <= scene.size.width * 0.2 || Player.entity.sprite.position.x >= scene.size.width * 0.8 || Player.entity.sprite.position.y <= scene.size.height * 0.2 || Player.entity.sprite.position.y >= scene.size.height * 0.8)
            {
                let go = Int(arc4random_uniform(UInt32(4)))
                if (go == 0)
                {
                    moveTo = Player.entity.sprite.position
                    moving = true
                }
            }
            
            while (moving == false)
            {
                moveTo.x = CGFloat(arc4random_uniform(UInt32(scene.size.width * 0.8 - enemySprite.frame.width))) + scene.size.width * 0.1 + enemySprite.frame.width
                moveTo.y = CGFloat(arc4random_uniform(UInt32(scene.size.height * 0.9 - enemySprite.frame.height))) + scene.size.height * 0.05 + enemySprite.frame.height
                let distance = hypotf(abs(Float(moveTo.x) - Float(enemySprite.position.x)), abs(Float(moveTo.y) - Float(enemySprite.position.y)))
                if (distance > 300)
                {
                    if (moveTo.x <= scene.size.width * 0.2 || moveTo.x >= scene.size.width * 0.8 || moveTo.y <= scene.size.height * 0.2 || moveTo.y >= scene.size.height * 0.8)
                    {
                        moving = true
                    }
                }
            }

        }
        if (enemySprite.physicsBody?.allContactedBodies().count > 0)
        {
            if (enemySprite.physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
            {
                moving = false
            }
        }

        if (finishedMove + 0.5 <= currentTime && moving == true)
        {
            let angle = abs(Double(atan(Double(moveTo.y - enemySprite.position.y)/Double(moveTo.x - enemySprite.position.x))))
            let moveX = abs(CGFloat(cos(angle) * moveSpeed))
            let moveY = abs(CGFloat(sin(angle) * moveSpeed))
        
            if (Int(enemySprite.position.x) < Int(moveTo.x) - 3)
            {
                enemySprite.position.x = enemySprite.position.x + moveX
            }
            else if (Int(enemySprite.position.x) > Int(moveTo.x) + 3)
            {
                enemySprite.position.x = enemySprite.position.x - moveX
            }
            else
            {
                moving = false
            }
            if (Int(enemySprite.position.y) < Int(moveTo.y) - 3)
            {
                enemySprite.position.y = enemySprite.position.y + moveY
            }
            else if (Int(enemySprite.position.y) > Int(moveTo.y) + 3)
            {
                enemySprite.position.y = enemySprite.position.y - moveY
            }
            else
            {
                finishedMove = currentTime
                moving = false
            }
        }
    }
    
}


class EnemyShotTrippleComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var moveTo = CGPoint()
    var shots = 0
    var shooter: EnemyEntity!
    var direction = 0
    let shotCooldownSeconds: NSTimeInterval = 1
    
    var lastShotTime: NSTimeInterval = 0
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.enemySprite = entity.sprite
        self.shooter = entity
        lastShotTime = scene.time
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (shots == 0 && lastShotTime + shotCooldownSeconds <= currentTime) {
            lastShotTime = currentTime
            direction = Int(arc4random_uniform(UInt32(4)))
            self.fire()
            shots += 1
        }
        else if (shots == 1 && lastShotTime + 0.25 <= currentTime)
        {
            lastShotTime = currentTime
            self.fire()
            shots += 1
        }
        else if (shots == 2 && lastShotTime + 0.25 <= currentTime)
        {
            lastShotTime = currentTime
            self.fire()
            shots = 0
        }
        
    }
    func fire()
    {
        let node = ShotNode()
        node.shooter = shooter
        for i in 0 ..< 3
        {
            let sprite = SKSpriteNode(imageNamed: "enemyTrippleShot")
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
            if (i == 0)
            {
                sprite.position = enemySprite.position
            }
            else if (i == 1)
            {
                if (direction == 0 || direction == 2)
                {
                    sprite.position = CGPoint(x: enemySprite.position.x + enemySprite.frame.width/2, y: enemySprite.position.y)
                }
                else
                {
                    sprite.position = CGPoint(x: enemySprite.position.x , y: enemySprite.position.y + enemySprite.frame.height/2)
                }
            }
            else
            {
                if (direction == 0 || direction == 2)
                {
                    sprite.position = CGPoint(x: enemySprite.position.x - enemySprite.frame.width/2, y: enemySprite.position.y)
                }
                else
                {
                    sprite.position = CGPoint(x: enemySprite.position.x , y: enemySprite.position.y - enemySprite.frame.height/2)
                }

            }
            self.followPath(sprite)
        }
        scene.addChild(node)
        
    }
    
    func followPath(sprite: SKSpriteNode)
    {
        var sequence = [SKAction]()
        moveTo.x = 0
        moveTo.y = 0
        if (direction == 0)
        {
            moveTo.y = 500
        }
        else if (direction == 1)
        {
            moveTo.x = 500
        }
        else if (direction == 2)
        {
            moveTo.y = -500
        }
        else
        {
            moveTo.x = -500
        }
        
        let action = SKAction.sequence([SKAction.moveTo(CGPoint(x: (enemySprite.position.x + moveTo.x), y: (enemySprite.position.y + moveTo.y)), duration: 4), SKAction.waitForDuration(3.0/60.0), SKAction.removeFromParent()])
        
        sequence += [action]
        
        sprite.runAction(SKAction.sequence(sequence))
    }
    
}

class EnemyBombDroppingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moving = false
    var shooter = EnemyEntity()
    let shotLength: NSTimeInterval = 3
    var nodes = [SKSpriteNode]()
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    var lastDamageDealt: NSTimeInterval = 0
    
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (lastShotTime + 2 <= currentTime)
        {
            self.drop()
            lastShotTime = currentTime
        }
    }
    func drop()
    {
        let node = ShotNode()
        let bomb = SKSpriteNode(imageNamed: "bomberShot")
        node.addChild(bomb)
        scene.addChild(node)
        bomb.physicsBody = SKPhysicsBody(rectangleOfSize: bomb.size)
        bomb.physicsBody?.allowsRotation = false
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.dynamic = false
        bomb.physicsBody?.friction = 0
        bomb.physicsBody?.usesPreciseCollisionDetection = true
        bomb.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        bomb.physicsBody?.contactTestBitMask = Constants.playerCategory
        bomb.physicsBody?.collisionBitMask = Constants.wallCategory
        bomb.position = enemySprite.position
        nodes.append(bomb)
        let textures = [SKTexture(imageNamed: "bombLit1"), SKTexture(imageNamed: "bombLit2"), SKTexture(imageNamed: "bombLit3")]
        let changeSkin = SKAction.animateWithTextures(textures, timePerFrame: 1)
        bomb.runAction(changeSkin)
        let action = SKAction.sequence([SKAction.waitForDuration(4), SKAction.runBlock({self.explode(bomb.position)}), SKAction.setTexture(SKTexture(imageNamed: "bossDragonShot1")), SKAction.waitForDuration(0.33), SKAction.runBlock({self.explode(bomb.position)}), SKAction.waitForDuration(0.33), SKAction.runBlock({self.explode(bomb.position)}), SKAction.waitForDuration(0.33), SKAction.runBlock({self.explode(bomb.position)}), SKAction.removeFromParent()])
        bomb.runAction(action)
    }
    
    func explode(position: CGPoint)
    {
        var moveTo = CGPoint()
        let explodeNode = ShotNode()
        explodeNode.shooter = shooter
        var moveTos = [CGPoint]()
        for i in 0 ..< 16
        {
            let angle = Float(Double(i) * M_PI/8.0)
            moveTo.y = position.y + CGFloat(sinf(angle) * 25.0)
            moveTo.x = position.x + CGFloat(cosf(angle) * 25.0)
            fire(position, node: explodeNode)
            moveTos.append(moveTo)
        }
        scene.addChild(explodeNode)
        for i in 0 ..< explodeNode.children.count
        {
            let action = SKAction.sequence([SKAction.moveTo(moveTos[i], duration: 0.5), SKAction.removeFromParent()])
            explodeNode.children[i].runAction(action)
        }
    }
    func fire(start: CGPoint, node: ShotNode)
    {
        
        let sprite = SKSpriteNode(imageNamed: String(format: "bossDragonShot%i", Int(arc4random_uniform(UInt32(4)))))
        node.addChild(sprite)
        sprite.position = start
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
        
    }
    
}

class EnemySludgeDroppingComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moveTo = CGPoint()
    var moving = false
    var shooter = EnemyEntity()
    let shotLength: NSTimeInterval = 3
    var nodes = [SKSpriteNode]()
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    var lastDamageDealt: NSTimeInterval = 0
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (lastShotTime + 1.5 <= currentTime)
        {
            self.drop()
            lastShotTime = currentTime
        }
        for i in 0 ..< nodes.count
        {
            if (nodes[i].physicsBody?.allContactedBodies().count > 0)
            {
                if (nodes[i].physicsBody?.allContactedBodies()[0].node?.physicsBody?.categoryBitMask == Constants.playerCategory)
                {
                    if(lastDamageDealt + 0.3 <= currentTime)
                    {
                        Player.damagePlayer(Double(shooter.rangeAttackPower))
                        lastDamageDealt = currentTime
                        Player.entity.lastHit = currentTime
                    }
                }
            }
            
        }
    }
    func drop()
    {
        let node = ShotNode()
        let sludge = SKSpriteNode(imageNamed: "enemySludge")
        node.addChild(sludge)
        scene.addChild(node)
        sludge.physicsBody = SKPhysicsBody(rectangleOfSize: sludge.size)
        sludge.physicsBody?.allowsRotation = false
        sludge.physicsBody?.affectedByGravity = false
        sludge.physicsBody?.dynamic = false
        sludge.physicsBody?.friction = 0
        sludge.physicsBody?.usesPreciseCollisionDetection = true
        sludge.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sludge.physicsBody?.contactTestBitMask = Constants.playerCategory
        sludge.physicsBody?.collisionBitMask = Constants.wallCategory
        sludge.position = enemySprite.position
        nodes.append(sludge)
        //        let action = SKAction.sequence([SKAction.waitForDuration(5.0), SKAction.removeFromParent()])
        //        sludge.runAction(action)
    }
    
    
}

class EnemyRingShotComponent: ActionComponent {
    var scene: GameScene!
    var enemySprite: SKNode!
    var coordinate: CGPoint!
    var moveTo = CGPoint()
    var moving = false
    var shooter = EnemyEntity()
    let shotCooldownSeconds: NSTimeInterval = 1
    
    var lastShotTime: NSTimeInterval = 0
    var playerSprite: SKSpriteNode!
    
    init(scene: GameScene, entity: EnemyEntity) {
        super.init()
        self.scene = scene
        self.shooter = entity
        self.enemySprite = shooter.sprite
        self.coordinate = shooter.sprite.position
        self.playerSprite = Player.entity.sprite
        lastShotTime = scene.time
        
        
        
    }
    
    override func action(currentTime: NSTimeInterval)
    {
        if (lastShotTime + shotCooldownSeconds <= currentTime) {
            lastShotTime = currentTime
            self.launch()
        }
        
    }
    func launch()
    {
        var moveTo = CGPoint()
        let ringNode = ShotNode()
        ringNode.shooter = shooter
        var moveTos = [CGPoint]()
        let startAngle = Float(Float(arc4random()) / Float(UINT32_MAX)) * Float(M_PI/8.0)
        for i in 0 ..< 16
        {
            let angle = Float(Double(i) * M_PI/8.0) + startAngle
            moveTo.y = enemySprite.position.y + CGFloat(sinf(angle) * 1000.0)
            moveTo.x = enemySprite.position.x + CGFloat(cosf(angle) * 1000.0)
            fire(ringNode)
            moveTos.append(moveTo)
        }
        scene.addChild(ringNode)
        for i in 0 ..< ringNode.children.count
        {
            let action = SKAction.sequence([SKAction.moveTo(moveTos[i], duration: 7.5), SKAction.removeFromParent()])
            ringNode.children[i].runAction(action)
        }
    }
    func fire(node: ShotNode)
    {
        
        let sprite = SKSpriteNode(imageNamed: String(format: "enemyRingShot", Int(arc4random_uniform(UInt32(4)))))
        node.addChild(sprite)
        sprite.position = enemySprite.position
        sprite.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        sprite.physicsBody?.allowsRotation = false
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.dynamic = true
        sprite.physicsBody?.friction = 0
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.categoryBitMask = Constants.enemyShotCategory
        sprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        sprite.physicsBody?.collisionBitMask = Constants.playerCategory | Constants.wallCategory
        
        
    }
    
}




class EnemyDyingComponent: ActionComponent {
    var scene:GameScene!
    var sprite:SKSpriteNode
    init(scene: GameScene, sprite: SKSpriteNode) {
        self.scene = scene
        self.sprite = sprite
        super.init()
    }
    override func action(currentTime: NSTimeInterval)
    {
        sprite.alpha -= 0.05
        if sprite.alpha <= 0.1
        {
            self.entity?.removeComponentForClass(EnemyDyingComponent)
            sprite.parent?.removeFromParent()
        }
    }
}


