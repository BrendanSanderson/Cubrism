//
//  EnemyEntity.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/12/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class EnemyEntity: DynamicEntity {
    var pointer = CGPoint()
    var node = EnemyNode()
    var scene = GameScene()
    var sprite = SKSpriteNode()
    var actions = [ActionComponent]()
    var type = String()
    var health = 50
    var currentHealth = 50
    var statusNode = SKSpriteNode()
    var meleeAttackPower = 25
    var rangeAttackPower = 25
    var experience = 5.0
    var level = 1
    override init()
    {
        
    }
    
    init(scene: GameScene, eType: String, lev: Int, elite: Bool)
    {
        super.init()
        self.scene = scene
        self.type = eType
        node.entity = self
        level = Player.currentViewController.level + lev - 1
        setUpType(eType, elite:elite)
        if (self.sprite.position == CGPoint())
        {
            if (type == "RangeRing" || type == "RangeTripple")
            {
                self.sprite.position = getNewCenterPosition(Player.entity.sprite.position)
            }
            else{
                self.sprite.position = getNewPosition(Player.entity.sprite.position)
            }
        }
        sprite.addChild(statusNode)
        statusNode.zPosition = sprite.zPosition + 1
        node.addChild(sprite)
        addComponent(VisualComponent(scene: scene, sprite: sprite))
        self.sprite.physicsBody?.categoryBitMask = Constants.enemyCategory
        self.sprite.physicsBody?.dynamic = true
        self.sprite.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.playerCategory
        if (type != "Melee")
        {
        self.sprite.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.doorCategory | Constants.wallCategory
    }
        else
        {
            self.sprite.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.doorCategory | Constants.wallCategory | Constants.playerCategory
        }
        scene.addChild(node)
        
    }
    
    convenience init (scene: GameScene)
    {
        self.init(scene: scene, eType: "Melee", lev:1, elite: false)
    }
    
    func setUpType (eType: String, elite: Bool)
    {
        var healthMultiplier = 1.0
        var rangeAttackMultiplier = 1.0
        var meleeAttackMultiplier = 1.0
        if eType == "Melee"
        {
            self.sprite = SKSpriteNode(imageNamed: "meleeEnemy")
            let trackingComponent = EnemyTrackingComponent(scene: scene, sprite: sprite, speed: 2.0)
            addComponent(trackingComponent)
            actions.append(trackingComponent)
            healthMultiplier = 1.5
            meleeAttackMultiplier = 2.0
            experience = 5.0
        }
        else if eType == "Suicide"
        {
            self.sprite = SKSpriteNode(imageNamed: "suicideEnemy")
            let trackingComponent = EnemyTrackingComponent(scene: scene, sprite: sprite, speed: 10.0)
            addComponent(trackingComponent)
            actions.append(trackingComponent)
            healthMultiplier = 0.01
            meleeAttackMultiplier = 4.0
            experience = 5.0
        }
        else if eType == "DragonFireball"
        {
            self.sprite = SKSpriteNode(imageNamed: "bossDragonFireball")
            let trackingComponent = EnemyTrackingComponent(scene: scene, sprite: sprite, speed: 4.0)
            addComponent(trackingComponent)
            actions.append(trackingComponent)
            healthMultiplier = 1.0
            meleeAttackMultiplier = 4.0
            experience = 0.0
            if (scene as! RoomScene).doors[0].direction == 1
            {
                sprite.position = CGPoint(x: scene.size.width * 0.15, y: scene.size.height/2)
            }
            else
            {
                sprite.position = CGPoint(x: scene.size.width * 0.85, y: scene.size.height/2)
            }
        }
            
        else if eType == "Dash"
        {
            self.sprite = SKSpriteNode(imageNamed: "dashEnemy")
            let dashComponent = EnemyDashMovementComponent(scene: scene, sprite: sprite, speed: 10.00)
            addComponent(dashComponent)
            actions.append(dashComponent)
            meleeAttackMultiplier = 2.0
            experience = 10.0
        }
            
        else if eType == "Range"
        {
            self.sprite = SKSpriteNode(imageNamed: "rangeEnemy")
            let movementComponent = EnemyRandomMovementComponent(scene: scene, sprite: sprite, speed: 0.75)
            let shootingComponent = EnemyShotTargetingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
            meleeAttackMultiplier = 0.5
            experience = 5.0
        }
        else if (type == "RangeTracking")
        {
            self.sprite = SKSpriteNode(imageNamed: "rangeTrackingEnemy")
            let movementComponent = EnemyRandomMovementComponent(scene: scene, sprite: sprite, speed: 0.33)
            let shootingComponent = EnemyShotTrackingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
            meleeAttackMultiplier = 0.5
            rangeAttackMultiplier = 4.0
            experience = 10.0
        }
        else if (type == "RangeTripple")
        {
            self.sprite = SKSpriteNode(imageNamed: "rangeTrippleEnemy")
            let movementComponent = EnemyRandomMovementComponent(scene: scene, sprite: sprite, speed: 0.4, distanceMult: 0.33)
            let shootingComponent = EnemyShotTrippleComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
            healthMultiplier = 2.0
            meleeAttackMultiplier = 0.5
            rangeAttackMultiplier = 0.75
            experience = 10.0
        }
        else if (type == "Sludge")
        {
            self.sprite = SKSpriteNode(imageNamed: "sludgeEnemy")
            let movementComponent = EnemyRandomMovementComponent(scene: scene, sprite: sprite, speed: 0.5)
            let sludgeComponent = EnemySludgeDroppingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(sludgeComponent)
            actions.append(sludgeComponent)
            healthMultiplier = 4.0
            meleeAttackMultiplier = 0.5
            rangeAttackMultiplier = 1.0
            experience = 7.5
        }
        else if (type == "Bomber")
        {
            self.sprite = SKSpriteNode(imageNamed: "bomberEnemy")
            let movementComponent = EnemyRandomMovementComponent(scene: scene, sprite: sprite, speed: 2)
            let bomberComponent = EnemyBombDroppingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(bomberComponent)
            actions.append(bomberComponent)
            healthMultiplier = 2.0
            meleeAttackMultiplier = 0.5
            rangeAttackMultiplier = 0.25
            experience = 7.5
        }
        
        else if (type == "RangeRing")
        {
            self.sprite = SKSpriteNode(imageNamed: "rangeRingEnemy")
            let ringShotComponent = EnemyRingShotComponent(scene: scene, entity: self)
            addComponent(ringShotComponent)
            actions.append(ringShotComponent)
            healthMultiplier = 1.0
            meleeAttackMultiplier = 0.5
            rangeAttackMultiplier = 0.5
            experience = 7.5
        }

        else
        {
            NSLog(type)
        }
        if elite == true
        {
            self.sprite.size = CGSize(width: sprite.size.width * 2, height: sprite.size.height * 2)
        }
        health = Int(100.0 * healthMultiplier * pow(Double(level), 0.8))
        currentHealth = health
        rangeAttackPower = Int(25.0 * rangeAttackMultiplier * Constants.enemyMultiplier(level))
        meleeAttackPower = Int(25.0 * meleeAttackMultiplier * Constants.enemyMultiplier(level))
        experience = (experience * Constants.expMultiplier(level))
    }
    
    
    
    func getNewPosition (position: CGPoint) -> CGPoint
    {
        var x = Int()
        var y = Int()
        var distance = Float()
        var newPosition = CGPoint()
        while (true)
        {
            x = Int(arc4random_uniform(UInt32(scene.frame.width*0.9 - 2*sprite.size.width))) + Int(scene.frame.width*0.05 + sprite.size.width)
            y = Int(arc4random_uniform(UInt32(scene.frame.height*0.8 - 2*sprite.size.height))) + Int(scene.frame.height*0.1 + sprite.size.height)
            newPosition = CGPoint(x: x, y: y)
            distance = hypotf(abs(Float(position.x) - Float(x)), abs(Float(position.y) - Float(y)))
            if (distance > 200)
            {
                return newPosition
            }
        }
    }
    
    func getNewCenterPosition (position: CGPoint) -> CGPoint
    {
        var x = Int()
        var y = Int()
        var distance = CGFloat()
        var newPosition = CGPoint()
        while (true)
        {
            x = Int(arc4random_uniform(UInt32(scene.frame.width*0.3 - 2*sprite.size.width))) + Int(scene.frame.width*0.35 + sprite.size.width)
            y = Int(arc4random_uniform(UInt32(scene.frame.height*0.3 - 2*sprite.size.height))) + Int(scene.frame.height*0.35 + sprite.size.height)
            newPosition = CGPoint(x: x, y: y)
            distance = CGFloat(hypotf(abs(Float(position.x) - Float(x)), abs(Float(position.y) - Float(y))))
            if (distance > Player.entity.sprite.size.height * 4.0)
            {
                return newPosition
            }
        }
    }
    
    override func act(currentTime: NSTimeInterval)
    {
        if (alive == true)
        {
            for i in 0 ..< (actions.count)
            {
                actions[i].action(currentTime)
            }
        }
        if (sprite.position.x > scene.size.width * 0.95 - sprite.size.width/2)
        {
            sprite.position.x = scene.size.width * 0.95 - sprite.size.width/2
        }
        else if (sprite.position.x < scene.size.width * 0.05 + sprite.size.width/2)
        {
            sprite.position.x = scene.size.width * 0.05 + sprite.size.width/2
        }
        if (sprite.position.y > scene.size.height * 0.9 - sprite.size.height/2)
        {
            sprite.position.y = scene.size.height * 0.9 - sprite.size.height/2
        }
        else if (sprite.position.y < scene.size.height * 0.1 + sprite.size.height/213)
        {
            sprite.position.y = scene.size.height * 0.1 + sprite.size.height/2
        }
    }
    
    func damageEnemy (damage: Int)
    {
        node.entity.currentHealth -= damage
        if (node.entity.currentHealth > 0)
        {
            statusNode.size = sprite.size
            if (Double(currentHealth)/Double(health) <= 0.25)
            {
                statusNode.texture = SKTexture(imageNamed: "damaged25")
            }
            else if (Double(currentHealth)/Double(health) <= 0.5)
            {
                statusNode.texture = SKTexture(imageNamed: "damaged50")
            }
            else if (Double(currentHealth)/Double(health) <= 0.75)
            {
                statusNode.texture = SKTexture(imageNamed: "damaged75")
            }
        }
        else if (node.entity.currentHealth <= 0)
        {
            sprite.physicsBody = nil
            self.removeComponentForClass(VisualComponent)
            if (type == "Melee" || type == "Suicide" || type == "DragonFireball")
            {
                self.removeComponentForClass(EnemyTrackingComponent)
            }
            else if (type == "Dash")
            {
                self.removeComponentForClass(EnemyDashMovementComponent)
            }
            else if (type == "Range")
            {
                self.removeComponentForClass(EnemyRandomMovementComponent)
                self.removeComponentForClass(EnemyShotTargetingComponent)
            }
            else if (type == "RangeTripple")
            {
                self.removeComponentForClass(EnemyRandomMovementComponent)
                self.removeComponentForClass(EnemyShotTrippleComponent)
            }
            else if (type == "RangeTracking")
            {
                self.componentForClass(EnemyShotTrackingComponent)?.bullet.removeFromParent()
                self.removeComponentForClass(EnemyRandomMovementComponent)
                self.removeComponentForClass(EnemyShotTrackingComponent)
            }
            else if (type == "Sludge")
            {
                let nodes = self.componentForClass(EnemySludgeDroppingComponent)?.nodes
                for i in 0 ..< nodes!.count
                {
                    nodes![i].parent?.removeFromParent()
                }
                self.removeComponentForClass(EnemyRandomMovementComponent)
                self.removeComponentForClass(EnemySludgeDroppingComponent)
            }
            else if (type == "Bomber")
            {
                let nodes = self.componentForClass(EnemyBombDroppingComponent)?.nodes
                for i in 0 ..< nodes!.count
                {
                    nodes![i].parent?.removeFromParent()
                }
                self.removeComponentForClass(EnemyRandomMovementComponent)
                self.removeComponentForClass(EnemyBombDroppingComponent)
            }
            else if (type == "RangeRing")
            {
                
                self.removeComponentForClass(EnemyRingShotComponent)
            }
            actions.removeAll()
            actions.append(EnemyDyingComponent(scene: scene, sprite: sprite))
            self.addComponent(actions[0])
            if (Player.level > level)
            {
                experience = experience/(Double(Player.level - level + 1)/2)
            }
            if (type != "DragonFireball")
            {
                scene.killEnemy(experience)
            }
        }
    }
}