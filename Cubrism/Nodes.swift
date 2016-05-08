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

