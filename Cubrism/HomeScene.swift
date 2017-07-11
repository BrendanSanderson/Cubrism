//
//  GameScene.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/3/16.
//  Copyright (c) 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class HomeScene: GameScene {
    var viewController = HomeViewController()
    var first = true
    var bank: VendorEntity!
    var shop: VendorEntity!
    override func didMove(to view: SKView) {
        
        /* Setup your scene here */
        addTeleporter()
        addVendors()
        addPlayer()
        Player.updatePlayer()
        super.didMove(to: view)
        
        
    }
    
    override func willMove(from view: SKView) {
        self.removeAllChildren()
        for i in (0 ..< self.view!.subviews.count).reversed()
        {
            if ((self.view!.subviews[i].isKind(of: UILabel.self)) == true)
            {
                self.view!.subviews[i].removeFromSuperview()
                
            }
        }
        

        super.willMove(from: view)
    }
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//       /* Called when a touch begins */
//        
//    }
   
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        super.update(currentTime)
    }
    func addPlayer()
    {
        Player.entity = PlayerEntity(scene: self)
        Player.currentScene = self
    }
    func addTeleporter()
    {
        let teleporterPosition = CGPoint(
            x: size.width/2,
            y: ((size.height * 0.8)))
      //  let teleporterSprite = SKSpriteNode(color: UIColor.whiteColor(), size: CGSize(width: 64, height: 32))
        let teleporterSprite = SKSpriteNode(imageNamed: "horizontalDoor")
        let teleporterNode = SKNode();
        teleporterNode.addChild(teleporterSprite)
        teleporterNode.position = teleporterPosition
        self.addChild(teleporterNode)
        teleporterSprite.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        teleporterSprite.physicsBody?.allowsRotation = false
        teleporterSprite.physicsBody?.affectedByGravity = false;
        teleporterSprite.physicsBody?.isDynamic = false
        teleporterSprite.physicsBody?.friction = 0;
        teleporterSprite.physicsBody?.usesPreciseCollisionDetection = true
        teleporterSprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        teleporterSprite.physicsBody?.categoryBitMask = Constants.teleporterCategory
        
    
    }
    func addVendors()
    {
        bank = VendorEntity(s: self, t: "bank")
        shop = VendorEntity(s: self, t: "shop")
    }
    override func didBegin(_ contact: SKPhysicsContact) {
        super.didBegin(contact)
    }
}
