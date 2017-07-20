
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var time = TimeInterval()
    var started = false
    var vending = false
    var vender: VendorPopUpNode!
    var doorAccessed = String()
    var world = Player.level/10 + 1
    let button = SKSpriteNode(imageNamed: "pauseButton")
    override func didMove(to view: SKView) {
        self.scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        self.view!.isMultipleTouchEnabled = true
        self.scene!.backgroundColor = UIColor(red: 20.0/255.0, green: 27.0/255.0, blue: 169.0/255.0, alpha: 1)
        self.scene!.backgroundColor = UIColor.clear
        createGrid()
        self.physicsWorld.contactDelegate = self
        super.didMove(to: view)
        if(Player.currentViewController != nil)
        {
            world = Player.currentViewController.world
        }
    }
    override func update(_ currentTime: TimeInterval) {
        time = currentTime
    }
    func createGrid()
    {
        let usableWidth = size.width * 0.9 // we only want to use 90% of the width available
        let usableHeight = size.height * 0.8 // we only want to use 80% of the height available
        
        let offsetX = (size.width - usableWidth) / 2 // used to center the grid horizontally
        let offsetY = (size.height - usableHeight) / 2 // used to center the grid vertically
        
        
        let gameFrame = CGRect(x: offsetX, y: offsetY, width: usableWidth, height: usableHeight)
        let frame = SKShapeNode(rect: gameFrame)
        frame.zPosition = -15
        let sn = SKSpriteNode(imageNamed:"border")
        sn.zPosition = -25
        if world >= 1
        {
            frame.fillColor = UIColor.white
            frame.fillTexture = SKTexture(imageNamed: String(format: "backgroundInner%i", world))
            frame.strokeColor = UIColor.black
            frame.glowWidth = 0
            sn.texture = SKTexture(imageNamed: String(format: "background%i", world))
        }
        else
        {
            frame.fillColor = UIColor(red: 78.0/255.0, green: 174.0/255.0, blue: 223.0/255.0, alpha: 1)
            frame.strokeColor = UIColor(red: 20.0/255.0, green: 27.0/255.0, blue: 169.0/255.0, alpha: 1)
            frame.glowWidth = 5
        }
        self.addChild(frame)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: gameFrame)
        self.physicsBody?.categoryBitMask = Constants.wallCategory
        self.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.playerCategory | Constants.enemyCategory | Constants.enemyShotCategory
        self.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.enemyShotCategory
        
        sn.size = CGSize(width: self.size.width, height: self.size.height)
        sn.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.addChild(sn)
        
        button.position = CGPoint(x: size.width * 0.975, y: size.height * 0.95)
        button.name = "pause"
        scene?.addChild(button)
        
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isPaused == false)
        {
            let touch = touches.first
            let but = atPoint(touch!.location(in: self))
            if  but.name == "pause"{
                if vending == false
                {
                    if (self.isKind(of: HomeScene.self))
                    {
                        self.addChild(PopUpNode(scene: self, text: "Paused", button1Text: "Play", button2Text: "Reset"))
                    }
                    else
                    {
                       self.addChild(PopUpNode(scene: self, text: "Paused", button1Text: "Play", button2Text: "Quit"))
                    }
                }
                else
                {
                    self.vender.removeFromParent()
                    button.texture = SKTexture(imageNamed: "pauseButton")
                    vending = false
                    Player.saveItems()
                    Player.updateEquipment()
                }
            }
        }
    }
    
    
    
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody = contact.bodyB
        var secondBody = contact.bodyA
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
        {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        let mask1 = firstBody.categoryBitMask
        let mask2 = secondBody.categoryBitMask
        
        if (mask1 == Constants.playerCategory && mask2 == Constants.teleporterCategory)
        {
            NSLog("teleporting")
            if (self.isKind(of: HomeScene.self) == true)
            {
                while (((self.view?.presentScene(nil)) == nil))
                {
                
                }
                //NSNotificationCenter.defaultCenter().postNotificationName("GoToFloorViewController", object: self)
                Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.disabled = true
                Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.removeFromParent()
                Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.disabled = true
                Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.removeFromParent()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToLevelSelectCollectionViewController"), object: self)
                
            }
            else if (self.isKind(of: RoomScene.self) == true)
            {
                Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.disabled = true
                Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.removeFromParent()
                Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.disabled = true
                Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.removeFromParent()
                self.physicsWorld.contactDelegate = nil
                //self.addChild(PopUpNode(scene: self, text: "You Won!", button1Text: "Retry", button2Text: "Leave"))
                NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCompletedViewController"), object: self)
                
            }
        }
        else if (mask1 == Constants.playerCategory && mask2 == Constants.doorCategory)
        {
            self.physicsWorld.contactDelegate = nil
            Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.disabled = true
            Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.removeFromParent()
            Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.disabled = true
            Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.removeFromParent()
            doorAccessed = (secondBody.node?.parent!.name)!
            NSLog("door")
            (Player.currentScene as? RoomScene)?.viewController.goToRoomScene()
           // NSNotificationCenter.defaultCenter().postNotificationName("GoToRoomScene", object: self)
        }
        else if (mask1 == Constants.playerCategory && (mask2 == Constants.enemyShotCategory || mask2 == Constants.enemyStatusShotCategory))
        {
            
            if (secondBody.node?.parent != nil)
            {
                let node = secondBody.node?.parent as! ShotNode
                if (node.shooter != nil)
                {
                
                Player.damagePlayer(Double(node.shooter.rangeAttackPower))
                    Player.entity.lastHit = time
                    secondBody.node?.removeFromParent()
                }
        
                else if (node.bossShooter != nil)
                {
                    if (node.type == "DragonBreathe")
                    {
                        Player.damagePlayer(Double(node.bossShooter.effectAttackPower))
                        Player.entity.lastHit = time
                        secondBody.node?.parent!.removeFromParent()
                    }
                    else
                    {
                        Player.damagePlayer(Double(node.bossShooter.rangeAttackPower))
                        Player.entity.lastHit = time
                        secondBody.node?.parent!.removeFromParent()
                    }
                }
            
            
            }
            NSLog("Shot Deleted")
        }
        else if (mask1 == Constants.playerCategory && mask2 == Constants.enemyTrackingShotCategory)
        {
            
            let node = secondBody.node?.parent as! ShotNode
            if (node.shooter != nil)
            {
                Player.damagePlayer(Double(node.shooter.rangeAttackPower))
                Player.entity.lastHit = time
                secondBody.node?.removeFromParent()
            }
            else if (node.bossShooter != nil)
            {
                Player.damagePlayer(Double(node.bossShooter.rangeAttackPower))
                Player.entity.lastHit = time
                secondBody.node?.removeFromParent()
            }
        }
       
        else if (mask1 == Constants.playerCategory && mask2 == Constants.enemyCategory)
        {
            if secondBody.node != nil && secondBody.node?.parent != nil
            {
            secondBody.node?.physicsBody?.contactTestBitMask = Constants.playerShotCategory
            let node = secondBody.node?.parent as! EnemyNode 
            if (node.Entity.type == "Suicide" || node.Entity.type == "DragonFireball")
            {
                Player.damagePlayer(Double(node.Entity.meleeAttackPower))
                Player.entity.lastHit = time
                node.Entity.damageEnemy(node.Entity.currentHealth)
            }
            else if(Player.entity.lastHit + 0.5 <= time)
            {
                Player.damagePlayer(Double(node.Entity.meleeAttackPower))
                Player.entity.lastHit = time
            }
            secondBody.node?.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.playerCategory
            }
        }
        else if (mask1 == Constants.playerCategory && mask2 == Constants.bossCategory)
        {
            if secondBody.node != nil && secondBody.node?.parent != nil
            {
                secondBody.node?.physicsBody?.contactTestBitMask = Constants.playerShotCategory
                let node = secondBody.node?.parent as! BossNode
                if(Player.entity.lastHit + 0.5 <= time)
                {
                    Player.damagePlayer(Double(node.Entity.meleeAttackPower))
                    Player.entity.lastHit = time
                }
                secondBody.node?.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.playerCategory
            }
        }
            
        else if (mask1 == Constants.playerCategory && mask2 == Constants.wallCategory)
        {
            if ((secondBody.node?.isKind(of: VendorNode.self)) == true)
            {
                if vending == false
                {
                    (secondBody.node as! VendorNode).Entity.act()
                    vending = true
                    button.texture = SKTexture(imageNamed: "closeButton")
                    self.vender = (secondBody.node as! VendorNode).Entity.popUp
                }
            }
        }
        else if (mask1 == Constants.enemyCategory && mask2 == Constants.playerShotCategory)
        {
            if firstBody.node != nil && firstBody.node?.parent != nil
            {
                let node = firstBody.node?.parent as! EnemyNode
                node.Entity.damageEnemy(Int(Player.attackPower))
                
            }
            secondBody.node?.parent!.removeFromParent()
            
            NSLog("Shot Deleted")
            
        }
        else if (mask1 == Constants.bossCategory && mask2 == Constants.playerShotCategory)
        {
            let node = firstBody.node?.parent as! BossNode
            node.Entity.damageBoss(Player.attackPower)
            secondBody.node?.parent!.removeFromParent()
            NSLog("Shot Deleted")
            
        }
            
        else if (mask1 == Constants.playerShotCategory && mask2 == Constants.wallCategory)
        {
            firstBody.node?.parent!.removeFromParent()
            NSLog("Shot Deleted")
        }
            
        else if (mask1 == Constants.enemyShotCategory && mask2 == Constants.wallCategory)
        {
            firstBody.node?.removeFromParent()
            NSLog("Shot Deleted")
        }
        else if (mask1 == Constants.enemyTrackingShotCategory && mask2 == Constants.wallCategory)
        {
            firstBody.node?.removeFromParent()
            NSLog("Shot Deleted")
        }
    
        
        
    }
    
    func killEnemy(_ exp: Double)
    {
        
    }

}
