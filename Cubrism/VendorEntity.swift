//
//  VendorEntity.swift
//  Cubrism
//
//  Created by Henry Sanderson on 4/1/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class VendorEntity: GKEntity {
    var scene: GameScene!
    var type: String!
    var sprite: VendorNode!
    let node = SKNode()
    init(s: GameScene, t: String)
    {
        super.init()
        scene = s
        type = t
        sprite = VendorNode(t: t)
        sprite.entity = self
        node.addChild(sprite)
        self.addComponent(VisualComponent(scene: scene, sprite: sprite))
        self.sprite.physicsBody?.categoryBitMask = Constants.wallCategory
        self.sprite.physicsBody?.dynamic = false
        self.sprite.physicsBody?.contactTestBitMask = Constants.playerShotCategory | Constants.playerCategory
        self.sprite.physicsBody?.collisionBitMask = Constants.playerShotCategory | Constants.playerCategory
        scene.addChild(node)
        
    }
    func act()
    {
        scene.addChild(VendorPopUpNode(scene:scene, text: "", button1Text: "", button2Text: ""))
    }
}
