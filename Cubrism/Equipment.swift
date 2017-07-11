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
    var price = 0
    var subType = ""
    
    init(t: String, lev: Int, tie: Int, st: String)
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
        price = level * tier * 3
        self.setStats()
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
            self.shield = 1 + 500 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            self.shieldRegen = 10 * ((multip * Double(level))/75) * (Player.playerMultiplier(level, mult: 1.2) - Player.playerMultiplier(level, mult: 1.1))
        }
        else if type == "Power Core"
        {
            self.attackPower = 1 + 100 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
            self.defence = 1 + 100 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            
            self.shield = 1 + 100 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            self.health = 50 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
        }
        else if type == "Pulsar"
        {
            self.attackPower = 1 + 500 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
        }
            
        else if type == "Special Pulsar"
        {
            self.attackSpeed = Double(tier * level/25)
        }
            
        else if type == "Armor Core"
        {
            self.health = 50 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
            self.defence = 1 + 150 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            
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
                self.attackPower = 1 + 100 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
            }
            else if subType == "Defence"
            {
                self.defence = 1 + 25 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            }
            else if subType == "Shield"
            {
                self.shield = 1 + 100 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.1))
            }
            else if subType == "Health"
            {
                self.health = 1 + 50 * ((multip * Double(level))/75) * (Constants.enemyMultiplier(level) - Player.playerMultiplier(level, mult: 1.2))
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
        return dic
    }
    convenience init(dic: [String: AnyObject])
    {
        var tSubType = ""
        if dic["subType"] != nil
        {
            tSubType = (dic["subType"] as? String)!
        }
        NSLog(tSubType)
        self.init(t: (dic["type"] as? String)!, lev: (dic["level"] as? Int)!, tie: (dic["tier"] as? Int)!, st: tSubType)
    }

}
