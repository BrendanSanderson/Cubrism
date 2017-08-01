//
//  Nodes.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/14/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit

class EnemyNode: SKNode {
    var Entity: EnemyEntity {
    get { return self.entity as! EnemyEntity }
    }
    override init() {
        super.init()
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
class BossNode: SKNode {
    var Entity: BossEntity {
        get { return self.entity as! BossEntity }
    }
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
    var Entity: VendorEntity {
     get { return self.entity as! VendorEntity }
    }
    
    init(t: String)
    {
        if t == "bank"
        {
            let texture = SKTexture(imageNamed: "bank")
            super.init(texture: texture, color: UIColor.clear, size: texture.size())
            self.position = CGPoint(x: Constants.w * 0.33, y: Constants.h * 0.8)
            self.type = t
        }
        else if t == "shop"
        {
            let texture = SKTexture(imageNamed: "merchant")
            super.init(texture: texture, color: UIColor.clear, size: texture.size())
            self.position = CGPoint(x: Constants.w * 0.67, y: Constants.h * 0.8)
            self.type = t
        }
        else
        {
            let texture = SKTexture(imageNamed: "playerIcon")
            super.init(texture: texture, color: UIColor.clear, size: texture.size())
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
        super.init(texture: texture, color: UIColor.clear, size: size)
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
        if(i.isKind(of: Equipment.self) && (i as! Equipment).tier > 1)
        {
            let e = i as! Equipment
            let imgName = e.type + String(e.variant)
            super.init(texture: SKTexture(imageNamed: imgName), size: CGSize(width: 32, height: 32))
        }
        else
        {
            super.init(texture: SKTexture(imageNamed: i.type), size: CGSize(width: 32, height: 32))
        }
        if i.quantity > 1
        {
            quantity = SKLabelNode(text: String(i.quantity))
            quantity.fontSize = 8
            quantity.fontName = "Arial"
            quantity.fontColor = UIColor.black
            quantity.horizontalAlignmentMode = .right
            
            quantity.position = CGPoint(x: 14, y: -14)
            quantity.zPosition = 1005
            addChild(quantity)
        }
        if item.isKind(of: Equipment.self)
        {
            tier = SKSpriteNode(texture: SKTexture(imageNamed: "tier\((i as! Equipment).tier)"), color: UIColor.clear, size: self.size)
            if ((i as! Equipment).tier == 0)
            {
                tier = SKSpriteNode(texture: SKTexture(imageNamed: "tier1"), color: UIColor.clear, size: self.size)
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
        super.init(texture: nil, color: Constants.darkColor, size: s)
        text = SKLabelNode(text: String("N/A"))
        text.fontSize = 24
        text.fontColor = Constants.lightColor
        text.fontName = "Arial"
        text.horizontalAlignmentMode = .center
        text.verticalAlignmentMode = .center
        text.zPosition = 1005
        text.position = CGPoint(x: 0 - (self.size.width * 0.1), y: 0)
        
        cost = SKLabelNode(text: String(""))
        cost.fontSize = 12
        cost.fontColor = Constants.lightColor
        cost.fontName = "Arial"
        cost.horizontalAlignmentMode = .right
        cost.verticalAlignmentMode = .bottom
        cost.zPosition = 1005
        cost.position = CGPoint(x: self.size.width * 0.5, y: 0)
        
        cubrixel = SKSpriteNode(texture: SKTexture(imageNamed: "Cubrixel"), color: UIColor.clear, size: CGSize(width: self.size.width * 0.2, height: self.size.width * 0.2))
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

