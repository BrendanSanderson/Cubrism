//
//  Equipment.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/25/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit

class Equipment: Item {
    var attackPower = 0.0
    var attackSpeed = 0.0
    var defence = 0.0
    var shieldRegen = 0.0
    var shield = 0.0
    var health = 0.0
    var level = 1
    var tier = 1
    var subType = "String"
    
    init(t: String, lev: Int, tie: Int)
    {
        super.init(t: t)
        level = lev
        tier = tie
        self.setStats()
    }
    convenience override init(t: String)
    {
        self.init(t: t, lev: 1, tie: 0)
    }
    
    convenience init (tie: Int, lev: Int)
    {
        let num = Int(arc4random_uniform(UInt32(Constants.itemType.count)))
        let type = Constants.itemType[num]
        self.init(t: type, lev: lev, tie: tie)
    }
    func setStats()
    {
        
        var multip = 2.0
        if (tier < 4)
        {
            multip = 0.75 + (0.25 * Double(tier))
        }
        
        
        
        
//        
//        if (type == "Shield")
//        {
//            subType = "Regen"
//            if (subType == "Regen")
//            {
//                 self.shieldRegen = ((multip * Double(level) * 1.2)/75) * (Player.playerMultiplier(level, mult: 1.2) - Player.playerMultiplier(level, mult: 1.1))
//                self.shield = ((multip * Double(level) * 0.8)/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
//            }
//            else if (subType == "Power")
//            {
//                self.shieldRegen = ((multip * Double(level) * 0.8)/75) * (Player.playerMultiplier(level, mult: 1.2) - Player.playerMultiplier(level, mult: 1.1))
//                self.shield = ((multip * Double(level) * 1.2)/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
//            }
//        }
        
        if (type == "Power Core" || type == "Pulsar" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.attackPower = ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
        }
        if (type == "Power Core" || type == "Pulsar" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.attackSpeed = Double(tier * level/10)
        }
        if (type == "Power Core" || type == "Shield" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.defence = ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
        }
        if (type == "Power Core" || type == "Shield" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.shield = ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
        }
        if (type == "Power Core" || type == "Shield" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.shieldRegen = ((multip * Double(level))/75) * (Player.playerMultiplier(level, mult: 1.2) - Player.playerMultiplier(level, mult: 1.1))
        }
        if (type == "Power Core" || type == "Armor Core" || type == "Attachment 1" || type == "Attachment 2")
        {
            self.health = ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
        }
        
    }
    
    
    override init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        self.level = aDecoder.decodeObjectForKey("level") as! Int
        self.tier = aDecoder.decodeObjectForKey("tier") as! Int
        self.setStats()
        
    }
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(level, forKey: "level")
        aCoder.encodeObject(tier, forKey: "tier")
    
    }
    
    override func toDictionary() -> [String:AnyObject]
    {
        var dic = super.toDictionary()
        dic["level"] = level
        dic["tier"] = tier
        return dic
    }
    convenience init(dic: [String: AnyObject])
    {
        self.init(t: (dic["type"] as? String)!, lev: (dic["level"] as? Int)!, tie: (dic["tier"] as? Int)!)
    }

}
