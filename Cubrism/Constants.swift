//
//  Constants.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/13/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit

class Constants: NSObject {
    static let playerCategory = UInt32(1)
    static let enemyCategory = UInt32(2)
    static let bossCategory = UInt32(4)
    static let playerShotCategory = UInt32(8)
    static let enemyShotCategory = UInt32(16)
    static let enemyTrackingShotCategory = UInt32(32)
    static let teleporterCategory = UInt32(64)
    static let doorCategory =  UInt32(128)
    static let wallCategory = UInt32(256)
    static var aspectMultiplier = 1
    
    static var w: CGFloat!
    static var h: CGFloat!
    static var uH: CGFloat!
    static var uW: CGFloat!
    static var merchantInventory = [Equipment]()
    static var itemType = ["Power Core", "Armor Core", "Pulsar", "Special Pulsar", "Shield", "Attachment"]
    
    static func enemyMultiplier(level: Int) -> Double{
        return pow((Double(level) + 4)/5 , 1.3)
    }
    static func expMultiplier(level: Int) -> Double{
        return pow((Double(level) + 5)/7 , 1.4)
    }
    
    static func forTailingZero(temp: Double) -> String{
        let tempVar = String(format: "%g", temp)
        return tempVar
    }
    static func updateMerchantInventory()
    {
        let num = Int(arc4random_uniform(UInt32(5)))
        merchantInventory.removeAll()
        merchantInventory.append(Equipment(t: "Power Core", lev: Player.level, tie: 1, st: ""))
        merchantInventory.append(Equipment(t: "Armor Core", lev: Player.level, tie: 1, st: ""))
        merchantInventory.append(Equipment(t: "Pulsar", lev: Player.level, tie: 1, st: ""))
        merchantInventory.append(Equipment(t: "Attachment", lev: Player.level, tie: 1, st: ""))
        merchantInventory.append(Equipment(t: "Attachment", lev: Player.level, tie: 1, st: ""))
        merchantInventory.append(Equipment(t: "Shield", lev: Player.level, tie: 1, st: ""))
        if num == 0
        {
            merchantInventory.append(Equipment(t: "Power Core", lev: Player.level, tie: 2, st: ""))
        }
        else if num == 1
        {
            merchantInventory.append(Equipment(t: "Armor Core", lev: Player.level, tie: 2, st: ""))
        }
        else if num == 2
        {
            merchantInventory.append(Equipment(t: "Pulsar", lev: Player.level, tie: 2, st: ""))
        }
        else if num == 3
        {
            merchantInventory.append(Equipment(t: "Attachment", lev: Player.level, tie: 2, st: ""))
        }
        else
        {
            merchantInventory.append(Equipment(t: "Shield", lev: Player.level, tie: 2, st: ""))
        }
    }
}
