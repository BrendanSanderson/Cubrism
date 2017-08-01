//
//  EnemyEntity.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/12/16.
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
    static var enemyDict = Constants.jsonDict?["enemy"] as? [String: Any]
    var componentDict: [String:Any]
    override init()
    {
        componentDict = (EnemyEntity.enemyDict?["component"] as? [String: Any])!
        super.init()
    }
    
    convenience init(scene: GameScene, eType: String, lev: Int, elite: Bool)
    {
        self.init()
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
        self.sprite.physicsBody?.isDynamic = true
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpType (_ eType: String, elite: Bool)
    {
        var healthMultiplier = 1.0
        var rangeAttackMultiplier = 1.0
        var meleeAttackMultiplier = 1.0
        var speed = 2.0
        let jType = String(describing: eType.characters.first!)
            .lowercased() + eType.substring(from: eType.characters.index(of: eType.characters.dropFirst().first!)!)
        let specificEnemyDict = EnemyEntity.enemyDict?[jType] as? [String: Any]
        healthMultiplier = (specificEnemyDict?["healthMult"] as? Double)!
        rangeAttackMultiplier = (specificEnemyDict?["rangeAttackMult"] as? Double)!
        meleeAttackMultiplier = (specificEnemyDict?["meleeAttackMult"] as? Double)!
        experience = (specificEnemyDict?["experience"] as? Double)!
        if let s = specificEnemyDict?["speed"] as? Double {
            speed = s
        }
        if(eType == "DragonFireball") {
            self.sprite = SKSpriteNode(imageNamed: "bossDragonFireball")
            if (scene as! RoomScene).doors[0].direction == 1
            {
                sprite.position = CGPoint(x: scene.size.width * 0.15, y: scene.size.height/2)
            }
            else
            {
                sprite.position = CGPoint(x: scene.size.width * 0.85, y: scene.size.height/2)
            }
        }
        else {self.sprite = SKSpriteNode(imageNamed: jType+"Enemy")}
        
        if eType == "Suicide" || eType == "DragonFireball" || eType == "Melee"
        {
            let trackingComponent = EnemyTrackingComponent(entity: self, speed: speed)
            addComponent(trackingComponent)
            actions.append(trackingComponent)
        }
        else if eType == "Dash"
        {
            let dashComponent = EnemyDashMovementComponent(entity: self, speed: speed)
            addComponent(dashComponent)
            actions.append(dashComponent)
        }
            
        else if eType == "Range"
        {
            let movementComponent = EnemyRandomMovementComponent(entity:self, speed: speed)
            let shootingComponent = EnemyShotTargetingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
        }
        else if (type == "RangeTracking")
        {
            let movementComponent = EnemyRandomMovementComponent(entity:self, speed: speed)
            let shootingComponent = EnemyShotTrackingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
        }
        else if (type == "RangeTripple")
        {
            let movementComponent = EnemyRandomMovementComponent(entity:self, variables: [speed,0.33])
            let shootingComponent = EnemyShotTrippleComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(shootingComponent)
            actions.append(shootingComponent)
        }
        else if (type == "Sludge")
        {
            let movementComponent = EnemyRandomMovementComponent(entity:self, speed: speed)
            let sludgeComponent = EnemySludgeDroppingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(sludgeComponent)
            actions.append(sludgeComponent)
        }
        else if (type == "Bomber")
        {
            let movementComponent = EnemyRandomMovementComponent(entity: self, speed: speed)
            let bomberComponent = EnemyBombDroppingComponent(scene: scene, entity: self)
            addComponent(movementComponent)
            actions.append(movementComponent)
            addComponent(bomberComponent)
            actions.append(bomberComponent)
        }
        
        else if (type == "RangeRing")
        {
            let ringShotComponent = EnemyRingShotComponent(scene: scene, entity: self)
            addComponent(ringShotComponent)
            actions.append(ringShotComponent)
        }

        else
        {
            NSLog(type)
        }
        if elite == true
        {
            self.sprite.size = CGSize(width: sprite.size.width * 2, height: sprite.size.height * 2)
        }
        health = Int(Player.healthBase * healthMultiplier * Constants.enemyMultiplier(level))
        currentHealth = health
        rangeAttackPower = Int(Player.attackPowerBase * rangeAttackMultiplier * Constants.enemyMultiplier(level))
        meleeAttackPower = Int(Player.attackPowerBase * meleeAttackMultiplier * Constants.enemyMultiplier(level))
        experience = (experience * Constants.expMultiplier(level))
    }
    
    
    
    func getNewPosition (_ position: CGPoint) -> CGPoint
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
    
    func getNewCenterPosition (_ position: CGPoint) -> CGPoint
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
    
    override func act(_ currentTime: TimeInterval)
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
    
    func damageEnemy (_ damage: Int)
    {
        node.Entity.currentHealth -= damage
        if (node.Entity.currentHealth > 0)
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
        else if (node.Entity.currentHealth <= 0)
        {
            sprite.physicsBody = nil
            self.removeComponent(ofType: VisualComponent.self)
            if (type == "Melee" || type == "Suicide" || type == "DragonFireball")
            {
                self.removeComponent(ofType: EnemyTrackingComponent.self)
            }
            else if (type == "Dash")
            {
                self.removeComponent(ofType: EnemyDashMovementComponent.self)
            }
            else if (type == "Range")
            {
                self.removeComponent(ofType: EnemyRandomMovementComponent.self)
                self.removeComponent(ofType: EnemyShotTargetingComponent.self)
            }
            else if (type == "RangeTripple")
            {
                self.removeComponent(ofType: EnemyRandomMovementComponent.self)
                self.removeComponent(ofType: EnemyShotTrippleComponent.self)
            }
            else if (type == "RangeTracking")
            {
                self.component(ofType: EnemyShotTrackingComponent.self)?.bullet.removeFromParent()
                self.removeComponent(ofType: EnemyRandomMovementComponent.self)
                self.removeComponent(ofType: EnemyShotTrackingComponent.self)
            }
            else if (type == "Sludge")
            {
                let nodes = self.component(ofType: EnemySludgeDroppingComponent.self)?.nodes
                for i in 0 ..< nodes!.count
                {
                    nodes![i].parent?.removeFromParent()
                }
                self.removeComponent(ofType: EnemyRandomMovementComponent.self)
                self.removeComponent(ofType: EnemySludgeDroppingComponent.self)
            }
            else if (type == "Bomber")
            {
                let nodes = self.component(ofType: EnemyBombDroppingComponent.self)?.nodes
                for i in 0 ..< nodes!.count
                {
                    nodes![i].parent?.removeFromParent()
                }
                self.removeComponent(ofType: EnemyRandomMovementComponent.self)
                self.removeComponent(ofType: EnemyBombDroppingComponent.self)
            }
            else if (type == "RangeRing")
            {
                
                self.removeComponent(ofType: EnemyRingShotComponent.self)
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
