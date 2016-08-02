//
//  GameScene.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/3/16.
//  Copyright (c) 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class HomeScene: GameScene {
    var viewController = HomeViewController()
    var first = true
    override func didMoveToView(view: SKView) {
        
        /* Setup your scene here */
        addTeleporter()
        addVendors()
        addPlayer()
        Player.updatePlayer()
        super.didMoveToView(view)
        
        
    }
    
    override func willMoveFromView(view: SKView) {
        self.removeAllChildren()
        for i in (0 ..< self.view!.subviews.count).reverse()
        {
            if ((self.view!.subviews[i].isKindOfClass(UILabel)) == true)
            {
                self.view!.subviews[i].removeFromSuperview()
                
            }
        }
        

        super.willMoveFromView(view)
    }
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//       /* Called when a touch begins */
//        
//    }
   
    override func update(currentTime: CFTimeInterval) {
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
        teleporterSprite.physicsBody?.dynamic = false
        teleporterSprite.physicsBody?.friction = 0;
        teleporterSprite.physicsBody?.usesPreciseCollisionDetection = true
        teleporterSprite.physicsBody?.contactTestBitMask = Constants.playerCategory
        teleporterSprite.physicsBody?.categoryBitMask = Constants.teleporterCategory
        
    
    }
    func addVendors()
    {
        let _ = VendorEntity(s: self, t: "bank")
        let _ = VendorEntity(s: self, t: "shop")
    }
    override func didBeginContact(contact: SKPhysicsContact) {
        super.didBeginContact(contact)
    }
}