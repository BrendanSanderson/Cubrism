
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var time = NSTimeInterval()
    var started = false
    var vending = false
    var vender: VendorPopUpNode!
    var doorAccessed = String()
    var world = 1
    override func didMoveToView(view: SKView) {
        self.scaleMode = .ResizeFill
        view.multipleTouchEnabled = true
        self.view!.multipleTouchEnabled = true
        self.scene!.backgroundColor = UIColor(red: 20.0/255.0, green: 27.0/255.0, blue: 169.0/255.0, alpha: 1)
        self.scene!.backgroundColor = UIColor.clearColor()
        createGrid()
        self.physicsWorld.contactDelegate = self
        super.didMoveToView(view)
        
    }
    override func update(currentTime: NSTimeInterval) {
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
            frame.fillColor = UIColor.whiteColor()
            frame.fillTexture = SKTexture(imageNamed: String(format: "backgroundInner%i", world))
            frame.strokeColor = UIColor.blackColor()
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
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: gameFrame)
        self.physicsBody?.categoryBitMask = Constants.wallCategory
        self.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.playerCategory | Constants.enemyCategory | Constants.enemyShotCategory
        self.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.enemyShotCategory
        
        sn.size = CGSize(width: self.size.width, height: self.size.height)
        sn.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        self.addChild(sn)
        
        
        let button = SKSpriteNode(imageNamed: "pauseButton")
        button.position = CGPoint(x: size.width * 0.975, y: size.height * 0.95)
        button.name = "pause"
        scene?.addChild(button)
        
        
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (self.paused == false)
        {
            let touch = touches.first
            let button = nodeAtPoint(touch!.locationInNode(self))
            if  button.name == "pause"{
                if vending == false
                {
                    self.addChild(PopUpNode(scene: self, text: "Paused", button1Text: "Play", button2Text: "Quit"))
                }
                else
                {
                    self.vender.removeFromParent()
                    vending = false
                    Player.saveItems()
                    Player.updateEquipment()
                }
            }
        }
    }
    
    
    
    
    
    
    func didBeginContact(contact: SKPhysicsContact) {
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
            if (self.isKindOfClass(HomeScene) == true)
            {
                while (((self.view?.presentScene(nil)) == nil))
                {
                
                }
                //NSNotificationCenter.defaultCenter().postNotificationName("GoToFloorViewController", object: self)
                NSNotificationCenter.defaultCenter().postNotificationName("GoToLevelSelectCollectionViewController", object: self)
                
            }
            else if (self.isKindOfClass(RoomScene) == true)
            {
                self.physicsWorld.contactDelegate = nil
                //self.addChild(PopUpNode(scene: self, text: "You Won!", button1Text: "Retry", button2Text: "Leave"))
                NSNotificationCenter.defaultCenter().postNotificationName("GoToCompletedViewController", object: self)
                
            }
        }
        else if (mask1 == Constants.playerCategory && mask2 == Constants.doorCategory)
        {
            self.physicsWorld.contactDelegate = nil
            doorAccessed = (secondBody.node?.parent!.name)!
            NSLog("door")
            (Player.currentScene as? RoomScene)?.viewController.goToRoomScene()
           // NSNotificationCenter.defaultCenter().postNotificationName("GoToRoomScene", object: self)
        }
        else if (mask1 == Constants.playerCategory && mask2 == Constants.enemyShotCategory)
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
            if (node.entity.type == "Suicide" || node.entity.type == "DragonFireball")
            {
                Player.damagePlayer(Double(node.entity.meleeAttackPower))
                Player.entity.lastHit = time
                node.entity.damageEnemy(node.entity.currentHealth)
            }
            else if(Player.entity.lastHit + 0.5 <= time)
            {
                Player.damagePlayer(Double(node.entity.meleeAttackPower))
                Player.entity.lastHit = time
            }
            secondBody.node?.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.playerCategory
            }
        }
            
        else if (mask1 == Constants.playerCategory && mask2 == Constants.wallCategory)
        {
            if ((secondBody.node?.isKindOfClass(VendorNode)) == true)
            {
                if vending == false
                {
                    (secondBody.node as! VendorNode).entity.act()
                    vending = true
                    self.vender = (secondBody.node as! VendorNode).entity.popUp
                }
            }
        }
        else if (mask1 == Constants.enemyCategory && mask2 == Constants.playerShotCategory)
        {
            if firstBody.node != nil && firstBody.node?.parent != nil
            {
                let node = firstBody.node?.parent as! EnemyNode
                node.entity.damageEnemy(Int(Player.attackPower))
                
            }
            secondBody.node?.parent!.removeFromParent()
            
            NSLog("Shot Deleted")
            
        }
        else if (mask1 == Constants.bossCategory && mask2 == Constants.playerShotCategory)
        {
            let node = firstBody.node?.parent as! BossNode
            node.entity.damageBoss(Player.attackPower)
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
    
    func killEnemy(exp: Double)
    {
        
    }

}
