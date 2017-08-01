//
//  Equipment.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/25/16.
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
    var price = 0
    var variant = 0
    var subType = ""
    
    init(t: String, lev: Int, tie: Int, st: String, v: Int)
    {
        super.init(t: t)
        level = lev
        tier = tie
        subType = st
        if tier == 0
        {
            tier = 1
        }
        if t == "Power   Core"
        {
            type = "Power Core"
        }
        self.variant = v
        price = level * tier * 3
        self.setStats()
    }
    convenience init (t: String, lev: Int, tie: Int, st: String)
    {
        let v = Int(arc4random_uniform(4))
        self.init(t: t, lev: lev, tie: tie, st: st, v: v)
    }
    
    
//    convenience init(t: String, lev: Int, tie: Int)
//    {
//        self.init(t: t, lev: 1, tie: 1, st: "")
//    }
    convenience override init(t: String)
    {
        self.init(t: t, lev: 1, tie: 1, st: "")
    }
    
    convenience init (tie: Int, lev: Int)
    {
        let num = Int(arc4random_uniform(UInt32(Constants.itemType.count)))
        let type = Constants.itemType[num]
        self.init(t: type, lev: lev, tie: tie, st: "")
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
        
        
        if type == "Shield"
        {
            self.shield = 1 + (multip/2.0) *
            (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            self.shieldRegen = 10 * (multip/2.0) * (Player.playerMultiplier(level, mult: 1.2) - Player.playerMultiplier(level, mult: 1.1))
        }
        else if type == "Power Core"
        {
            self.attackPower = 1 + (multip/8.0) *
                (((Player.attackPowerBase * Constants.enemyMultiplier(level)) - 0.25 * Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))

            self.defence = 1 + 1 + (multip/8.0) *
                (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            
            self.shield = (multip/8.0) *
                (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            self.health = 1 + (multip/8.0) *
                (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
        }
        else if type == "Pulsar"
        {
            self.attackPower = 1 + (multip/2.0) *
                (((Player.attackPowerBase * Constants.enemyMultiplier(level)) - 0.25 * Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
        }
            
        else if type == "Special Pulsar"
        {
            self.attackSpeed = Double(tier * level/25)
        }
            
        else if type == "Armor Core"
        {
            self.health = 1 + (multip/2.0) *
            ((4.0 * (Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            self.defence = 1 + (multip/4.0) *
                (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            
        }
        else if type == "Attachment"
        {
            if subType == ""
            {
                let num = Int(arc4random_uniform(UInt32(4)))
                if num == 0
                {
                    self.subType = "AttackPower"
                }
                else if num == 1
                {
                    self.subType = "Defence"
                }
                else if num == 2
                {
                    self.subType = "Shield"
                }
                else
                {
                    self.subType = "Health"
                }
            }
            if subType == "AttackPower"
            {
                self.attackPower = 1 + (multip/10.0) *
                    (((Player.attackPowerBase * Constants.enemyMultiplier(level)) - 0.25 * Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            }
            else if subType == "Defence"
            {
                self.defence = 1 + (multip/10.0) *
                    (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            }
            else if subType == "Shield"
            {
                self.shield = 1 + (multip/10.0) *
                    (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            }
            else if subType == "Health"
            {
                self.health = 1 + (multip/10.0) *
                    (((4.0 * Player.attackPowerBase * Constants.enemyMultiplier(level)) - Player.healthBase * Player.playerMultiplier(level, mult: Player.healthExp)))
            }
        }
        
        
    }
    override init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        self.level = aDecoder.decodeObject(forKey: "level") as! Int
        self.tier = aDecoder.decodeObject(forKey: "tier") as! Int
        self.setStats()
        
    }
    override func encodeWithCoder(_ aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encode(level, forKey: "level")
        aCoder.encode(tier, forKey: "tier")
    
    }
    
    override func toDictionary() -> [String:AnyObject]
    {
        var dic = super.toDictionary()
        dic["level"] = level as AnyObject
        dic["tier"] = tier as AnyObject
        dic["subType"] = subType as AnyObject
        dic["variant"] = variant as AnyObject
        return dic
    }
    convenience init(dic: [String: AnyObject])
    {
        var tSubType = ""
        if dic["subType"] != nil
        {
            if dic["subType"] as! String != ""
            {
             print(dic["subType"] as! String)
            }
            tSubType = (dic["subType"] as? String)!
        }
        var v = Int(arc4random_uniform(4))
        if dic["variant"] != nil
        {
            v = dic["variant"] as! Int
        }
        self.init(t: (dic["type"] as? String)!, lev: (dic["level"] as? Int)!, tie: (dic["tier"] as? Int)!, st: tSubType, v: v)
    }

}
