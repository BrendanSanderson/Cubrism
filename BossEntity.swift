//
//  BossEntity.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/16/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit

class BossEntity: DynamicEntity {
    var node = BossNode()
    var scene = GameScene()
    var sprite: SKSpriteNode!
    var actions = [ActionComponent]()
    var constantActions = [ActionComponent]()
    var health = 1000.0
    var currentHealth = 1000.0
    var statusNode = SKSpriteNode()
    var rangeAttackPower = 50
    var meleeAttackPower = 25
    var effectAttackPower = 10
    var level = 1
    var attack: ActionComponent!
    var firstAttack = true
    var exp = 50.0
    var lastShot:NSTimeInterval = 0
    var type: String!
    override init()
    {
        
    }
    
    init(scene: GameScene, properties: NSDictionary)
    {
        super.init()
        self.scene = scene
        node.entity = self
        level = (scene as! RoomScene).viewController.level
        type = properties.valueForKey("name") as? String!
        setUpBoss(properties)
        node.addChild(sprite)
        addComponent(VisualComponent(scene: scene, sprite: sprite))
        sprite.zPosition = 10
        addComponent(BossBarComponent(scene: scene))
        sprite.physicsBody?.dynamic = false
        if (properties.valueForKey("name") as? String!) == "golem"
        {
            sprite.physicsBody?.dynamic = true
        }
        
        self.sprite.physicsBody?.categoryBitMask = Constants.bossCategory
        self.sprite.physicsBody?.contactTestBitMask = Constants.playerShotCategory
        self.sprite.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.playerCategory | Constants.wallCategory
        scene.addChild(node)
    }
    func setUpBoss (properties: NSDictionary)
    {
        var rangeMult = 50
        var effectMult = 10
        var meleeMult = 25
        self.sprite = SKSpriteNode(texture: SKTexture(imageNamed: (properties.valueForKey("image") as? String)!), size: CGSize(width: (properties.valueForKey("size") as? Int)!, height: (properties.valueForKey("size") as? Int)!))
        if (properties.valueForKey("position") as? String)! == "center"
        {
            sprite.position = CGPoint(x: scene.frame.width/2.0, y: scene.frame.height/2.0)
        }
        if (properties.valueForKey("name") as? String!) == "generator"
        {
            let comp = BossSprayComponent(scene: scene, sprite: sprite, entity: self)
            addComponent(comp)
            actions.append(comp)
            let comp2 = BossElectricFieldComponent(scene: scene, sprite: sprite, entity: self)
            addComponent(comp2)
            actions.append(comp2)
            let comp3 = BossShotTargetingComponent(scene: scene, entity: self, image: "bossGeneratorShot")
            addComponent(comp3)
            constantActions.append(comp3)
            sprite.size = CGSize(width: scene.frame.height * 0.2, height: scene.frame.height * 0.2)

        }
        else if (properties.valueForKey("name") as? String!) == "dragon"
        {
            sprite.size = CGSize(width: scene.frame.height * 0.3 * (10.0/7.0), height: scene.frame.height * 0.3)
            let comp = BossDragonBreatheComponent(scene: scene, sprite: sprite, entity: self)
            addComponent(comp)
            actions.append(comp)
            let comp2 = BossDragonFireballComponent(scene: scene, sprite: sprite, entity: self)
            addComponent(comp2)
            actions.append(comp2)
            
            let comp3 = BossShotTargetingComponent(scene: scene, entity: self, image: "bossDragonShot0")
            addComponent(comp3)
            constantActions.append(comp3)
            
            let comp4 = BossDragonHeadTilt(scene: scene, entity: self)
            addComponent(comp4)
            constantActions.append(comp4)
            if (scene as! RoomScene).doors[0].direction == 1
            {
                sprite.xScale *= -1
                sprite.position = CGPoint(x: sprite.size.height/2.5, y: scene.frame.height/2.0)
            }
            else
            {
                sprite.position = CGPoint(x: scene.frame.width - sprite.size.height/2.5, y: scene.frame.height/2.0)
            }
        }
        else if (properties.valueForKey("name") as? String!) == "golem"
        {
            let comp = GolemDropComponent(scene: scene, entity: self)
            addComponent(comp)
            actions.append(comp)
            
            let comp2 = BossGolemRockShoot(scene: scene, entity: self)
            addComponent(comp2)
            actions.append(comp2)
            
            sprite.size = CGSize(width: scene.frame.height * 0.2, height: scene.frame.height * 0.2)
            let comp4 = BossGolemJumpComponent(scene: scene, entity: self)
            addComponent(comp4)
            constantActions.append(comp4)
            
            let comp3 = BossTrackingComponent(scene: scene, entity: self, speed: 1.5)
            addComponent(comp3)
            constantActions.append(comp3)
            meleeMult = 100
            effectAttackPower = 25
            
        }
        health = Double(1000.0 * Constants.enemyMultiplier(level))
        currentHealth = health
        rangeAttackPower = Int(Double(rangeMult) * Constants.enemyMultiplier(level))
        meleeAttackPower = Int(Double(meleeMult) * Constants.enemyMultiplier(level))
        effectAttackPower = Int(Double(effectAttackPower) * Constants.enemyMultiplier(level))
        exp = (exp * Constants.expMultiplier(level))
    }
    
    override func act(currentTime: NSTimeInterval)
    {
        if (actions.count > 0 && currentHealth/health <= 0.8)
        {
            if (firstAttack == true)
            {
                attack = actions[Int(arc4random_uniform(UInt32(actions.count)))]
                firstAttack = false
                attack.action(currentTime)
            }
            else if (attack.acting == false && lastShot +  NSTimeInterval(3) <= currentTime)
            {
                attack = actions[Int(arc4random_uniform(UInt32(actions.count)))]
                attack.action(currentTime)
            }
            else if (attack.acting == true)
            {
                attack.action(currentTime)
                lastShot = currentTime
            }
        }
        if (alive == true)
        {
            for i in 0 ..< constantActions.count
            {
                constantActions[i].action(currentTime)
            }
        }
    }
    
    
    func damageBoss (damage: Double)
    {
        node.entity.currentHealth -= damage
        
        self.componentForClass(BossBarComponent)?.updateBars(currentHealth, totalHealth: health)
                    
        if (node.entity.currentHealth <= 0)
        {
            sprite.physicsBody = nil
            self.removeComponentForClass(VisualComponent)
            self.removeComponentForClass(BossBarComponent)
            self.removeComponentForClass(BossShotTargetingComponent)
            if (type == "generator")
            {
                self.removeComponentForClass(BossElectricFieldComponent)
                self.removeComponentForClass(BossSprayComponent)
            }
            else if (type == "dragon")
            {
                self.removeComponentForClass(BossDragonBreatheComponent)
                self.removeComponentForClass(BossDragonFireballComponent)
                self.removeComponentForClass(BossDragonHeadTilt)
            }
            else if (type == "golem")
            {
                self.componentForClass(GolemDropComponent)?.node.removeFromParent()
                self.removeComponentForClass(BossGolemJumpComponent)
                self.removeComponentForClass(BossTrackingComponent)
                self.removeComponentForClass(GolemDropComponent)
                self.removeComponentForClass(BossGolemRockShoot)

            }
            actions.removeAll()
            constantActions.removeAll()
            actions.append(EnemyDyingComponent(scene: scene, sprite: sprite))
            attack = actions[0]
            self.addComponent(actions[0])
            scene.killEnemy(50.0)
            alive = false
            if (scene as! RoomScene).name == "bossRoom"
            {
                (scene as! RoomScene).addTeleporter(CGPoint(x: scene.size.width/2, y: scene.size.height/2))
            }
        }
    }

}