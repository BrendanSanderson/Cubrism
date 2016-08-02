//
//  EnemyNode.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/14/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit

class EnemyNode: SKNode {
    var entity: EnemyEntity!
    override init() {
        super.init()
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
class BossNode: SKNode {
    var entity: BossEntity!
    override init() {
        super.init()
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
class ShotNode: SKNode {
    var type = String()
    var shooter: EnemyEntity!
    var bossShooter: BossEntity!
    override init() {
        super.init()
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class VendorNode: SKSpriteNode {
    var type = String()
    var entity: VendorEntity!
    
    init(t: String)
    {
        if t == "bank"
        {
            let texture = SKTexture(imageNamed: "bank")
            super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
            self.position = CGPoint(x: Constants.w * 0.33, y: Constants.h * 0.8)
            self.type = t
        }
        else if t == "shop"
        {
            let texture = SKTexture(imageNamed: "merchant")
            super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
            self.position = CGPoint(x: Constants.w * 0.67, y: Constants.h * 0.8)
            self.type = t
        }
        else
        {
            let texture = SKTexture(imageNamed: "playerIcon")
            super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SelectNode: SKSpriteNode
{
    init(texture: SKTexture, size: CGSize)
    {
        super.init(texture: texture, color: UIColor.clearColor(), size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ItemNode: SelectNode {
    var quantity: SKLabelNode!
    var tier: SKSpriteNode!
    var item: Item!
    init (i: Item)
    {
        self.item = i
        super.init(texture: SKTexture(imageNamed: i.type), size: CGSize(width: 32, height: 32))
        if i.quantity > 1
        {
            quantity = SKLabelNode(text: String(i.quantity))
            quantity.fontSize = 8
            quantity.fontName = "Arial"
            quantity.horizontalAlignmentMode = .Right
            
            quantity.position = CGPoint(x: 14, y: -14)
            quantity.zPosition = 1005
            addChild(quantity)
        }
        if item.isKindOfClass(Equipment)
        {
            tier = SKSpriteNode(texture: SKTexture(imageNamed: "tier\((i as! Equipment).tier)"), color: UIColor.clearColor(), size: self.size)
            if ((i as! Equipment).tier == 0)
            {
                tier = SKSpriteNode(texture: SKTexture(imageNamed: "tier1"), color: UIColor.clearColor(), size: self.size)
            }
            tier.zPosition = self.zPosition - 1
            self.addChild(tier)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class SellNode: SKSpriteNode
{
    var text: SKLabelNode!
    var cubrixel: SKSpriteNode!
    var cost: SKLabelNode!
    init(s : CGSize)
    {
        super.init(texture: nil, color: UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1), size: s)
        text = SKLabelNode(text: String("N/A"))
        text.fontSize = 24
        text.fontColor = UIColor.whiteColor()
        text.fontName = "Arial"
        text.horizontalAlignmentMode = .Center
        text.verticalAlignmentMode = .Center
        text.zPosition = 1005
        text.position = CGPoint(x: 0 - (self.size.width * 0.1), y: 0)
        
        cost = SKLabelNode(text: String(""))
        cost.fontSize = 12
        cost.fontColor = UIColor.whiteColor()
        cost.fontName = "Arial"
        cost.horizontalAlignmentMode = .Right
        cost.verticalAlignmentMode = .Bottom
        cost.zPosition = 1005
        cost.position = CGPoint(x: self.size.width * 0.5, y: 0)
        
        cubrixel = SKSpriteNode(texture: SKTexture(imageNamed: "Cubrixel"), color: UIColor.clearColor(), size: CGSize(width: self.size.width * 0.2, height: self.size.width * 0.2))
        cubrixel.zPosition = 1005
        cubrixel.position = CGPoint(x: self.size.width * 0.4, y: 0 - (self.size.width * 0.1))
        addChild(cubrixel)
        addChild(text)
        addChild(cost)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func back()
    {
        self.zPosition = -4
        text.zPosition = -3
        cubrixel.zPosition = -2
        cost.zPosition = -1
        
        
    }
    func front()
    {
        self.zPosition = 1005
        text.zPosition = 1003
        cubrixel.zPosition = 1005
        cost.zPosition = 1005
    }
}

