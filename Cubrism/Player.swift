//
//  Player.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/14/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class Player: NSObject {
    static var health = 100.0
    static var shield = 100.0
    static var currentShield = 100.0
    static var currentHealth = 100.0
    static var attackPower = 25.0
    static var attackSpeed = 25.0
    static var shieldRegen = 0.3
    static var level = UserDefaults.standard.object(forKey: "Level") as! Int
    static var entity = PlayerEntity()
    static var defence = 0.0
    static var exp = UserDefaults.standard.object(forKey: "Experience") as! Int
    static var totalExp = UserDefaults.standard.object(forKey: "TotalExperience") as! Int
    static var currentScene: GameScene!
    static var currentViewController: FloorViewController!
    static var gearDict : [String:[String : AnyObject]]!
    static var gear : [String : Equipment]!
    static var inventoryDict = UserDefaults.standard.object(forKey: "Inventory") as! [[String : AnyObject]]
    static var inventory = UserDefaults.standard.object(forKey: "Inventory") as! [Item]
    static var attackPowerBoost = 0.0
    static var attackSpeedBoost = 0.0
    static var defenceBoost = 0.0
    static var shieldBoost = 0.0
    static var healthBoost = 0.0
    static var shieldRegenBoost = 0.0
    static var shotCoolDownSeconds = 0.5
    static var alive = true
    static var expGained = 0
    
    static func updatePlayer()
    
    {
        
        alive = true
        health = 100.0 * Player.playerMultiplier(level, mult: 1.2) + healthBoost
        shield = 100.0 * Player.playerMultiplier(level, mult: 1.1) + shieldBoost
        defence = defenceBoost
        attackPower = 2500.0 * Player.playerMultiplier(level, mult: 1.1) + attackPowerBoost
        shieldRegen = 0.3 * (Player.playerMultiplier(level, mult: 1.0) + shieldRegenBoost/10.0)
        shotCoolDownSeconds = 0.5 - (attackSpeedBoost/40)
        currentHealth = health
        currentShield = shield
        if totalExp < totalExpToLevel(Player.level)
        {
            let ex = totalExp
            totalExp = 0
            exp = 0
            level = 1
            self.augmentExperience(ex)
        }
        
    }
    static func updateEquipment()
    {
        attackPowerBoost = (gear["Power Core"]?.attackPower)! + (gear["Pulsar"]?.attackPower)! + (gear["Attachment 1"]?.attackPower)! + (gear["Attachment 2"]?.attackPower)!
        
        attackSpeedBoost = (gear["Power Core"]?.attackSpeed)! + (gear["Pulsar"]?.attackSpeed)! + (gear["Attachment 1"]?.attackSpeed)! + (gear["Attachment 2"]?.attackSpeed)!
        
        defenceBoost = (gear["Power Core"]?.defence)! + (gear["Armor Core"]?.defence)! + (gear["Shield"]?.defence)! + (gear["Attachment 1"]?.defence)! + (gear["Attachment 2"]?.defence)!
        
        shieldBoost = (gear["Power Core"]?.shield)! + (gear["Shield"]?.shield)! + (gear["Attachment 1"]?.shield)! + (gear["Attachment 2"]?.shield)!
        
        shieldRegenBoost = (gear["Power Core"]?.shieldRegen)! + (gear["Shield"]?.shieldRegen)! + (gear["Attachment 1"]?.shieldRegen)! + (gear["Attachment 2"]?.shieldRegen)!
        
        healthBoost = (gear["Power Core"]?.shield)! + (gear["Armor Core"]?.shield)! + (gear["Attachment 1"]?.shield)! + (gear["Attachment 2"]?.shield)!
        

    }
    
    static func updateInventory()
    {
        inventory.removeAll()
        for i in 0 ..< inventoryDict.count
        {
            var dic = inventoryDict[i]
            
            if dic["tier"] != nil
            {
                inventory.append(Equipment(dic: dic))
            }
            else
            {
                inventory.append(Item(dic: dic))
            }
        }
        Player.gearDict = UserDefaults.standard.object(forKey: "Gear") as! [String:[String : AnyObject]]
        Player.gear = ["Power Core": Equipment(dic: gearDict["Power Core"]!), "Armor Core": Equipment(dic: gearDict["Armor Core"]!), "Pulsar" : Equipment(dic: gearDict["Pulsar"]!), "Special Pulsar" : Equipment(dic: gearDict["Special Pulsar"]!), "Shield" : Equipment(dic: gearDict["Shield"]!), "Attachment 1" : Equipment(dic: gearDict["Attachment 1"]!), "Attachment 2" : Equipment(dic: gearDict["Attachment 2"]!)]
        
    }
    static func damagePlayer(_ damage: Double)
    {
        let dam = damage - defence/10.0
        
        if (currentShield >= dam)
        {
            currentShield -= dam
        }
        else if (currentShield > 0 && dam > currentShield)
        {
            currentHealth -= (dam - currentShield)
            currentShield = 0
        }
        else if (currentHealth > 0)
        {
            currentHealth -= dam
            
        }
        
        if (currentHealth <= 0 && alive == true)
        {
            entity.component(ofType: HealthBarComponent.self)!.updateBars(0, health: 0)
            currentViewController.levelExp = currentViewController.levelExp/2
            
            var levelGap = Player.level - currentViewController.level
            var augExp = currentViewController.levelExp
            if (levelGap > 5)
            {
                levelGap = 5
            }
            if (levelGap > 0)
            {
                augExp = (currentViewController.levelExp)/(levelGap)
            }
            
            expGained = augExp
            
            Player.augmentExperience(augExp)
            augmentExperience(currentViewController.levelExp)
            currentScene.addChild(PopUpNode(scene: currentScene, text: "You are Dead.", button1Text: "Retry", button2Text: "Leave"))
            alive = false
            return
        }
        else
        {
            entity.component(ofType: HealthBarComponent.self)!.updateBars(currentShield, health: currentHealth)
        }
        
    }
    static func act()
    {
        if (entity.lastHit + 2 <= currentScene.time && currentShield < shield)
        {
            currentShield += shieldRegen
            entity.component(ofType: HealthBarComponent.self)!.updateBars(currentShield, health: currentHealth)
        }
        if (entity.sprite.position.x > currentScene.size.width * 0.95 - entity.sprite.size.width/2)
        {
            entity.sprite.position.x = currentScene.size.width * 0.95 - entity.sprite.size.width/2
        }
        else if (entity.sprite.position.x < currentScene.size.width * 0.05 + entity.sprite.size.width/2)
        {
            entity.sprite.position.x = currentScene.size.width * 0.05 + entity.sprite.size.width/2
        }
        if (entity.sprite.position.y > currentScene.size.height * 0.9 - entity.sprite.size.height/2)
        {
            entity.sprite.position.y = currentScene.size.height * 0.9 - entity.sprite.size.height/2
        }
        else if (entity.sprite.position.y < currentScene.size.height * 0.1 + entity.sprite.size.height/213)
        {
            entity.sprite.position.y = currentScene.size.height * 0.1 + entity.sprite.size.height/2
        }
    }
    static func augmentExperience(_ experience: Int)
    {
        exp += experience
        totalExp += experience
        while (exp >= expToLevel(level))
        {
            exp -= expToLevel(level)
            level += 1
        }
        Constants.updateMerchantInventory()
        UserDefaults.standard.set(level, forKey: "Level")
        UserDefaults.standard.set(exp, forKey: "Experience")
        UserDefaults.standard.set(totalExp, forKey: "TotalExperience")
        UserDefaults.standard.synchronize()
        
    }
    
    static func expToLevel(_ level: Int) -> Int
    {
        var total = 0.0
//        for     i in 1 ... level
//        {}
        total += floor(Double(level) + 300.0 * pow(2.0, Double(level) / 4.0))
        
        return  Int((floor(total / 4)))

    }
    static func totalExpToLevel(_ level: Int) -> Int
    {
    var total = 0.0
    for i in 1 ... level
    {
        total += floor(Double(i) + 300.0 * pow(2.0, Double(i) / 4.0))
    }
    return  Int((floor(total / 4)))
    
    }
    static func playerMultiplier(_ level: Int, mult: Double) -> Double{
        return pow((Double(level) + 4)/5, mult)
    }
    static func addDrop (_ item: Item)
    {
        var arr = [Item]()
        arr.append(item)
        addDrops(arr)
    }
    static func addDrops(_ items: [Item])
    {
        for i in 0 ..< items.count
        {
            
            if (items[i].isKind(of: Equipment.self) == true)
            {
                inventory.append((items[i] as? Equipment)!)
            }
            else if items[i].stackable == false
            {
                inventory.append(items[i])
            }
            else
            {
                var num = -1
                for j in 0 ..< inventory.count
                {
                    if inventory[j].type == items[i].type
                    {
                        num = j
                    }
                }
                if num == -1
                {
                    inventory.append(items[i])
                }
                else
                {
                    inventory[num].quantity += items[i].quantity
                }
                
            }
        }
        
        Player.saveItems()
        
        
        self.updateEquipment()
    }
    
    static func saveItems()
    {
        Player.inventoryDict.removeAll()
        for i in 0 ..< Player.inventory.count
        {
            Player.inventoryDict.append(Player.inventory[i].toDictionary())
        }
        
        Player.gearDict = ["Power Core": gear["Power Core"]!.toDictionary(), "Armor Core": gear["Armor Core"]!.toDictionary(), "Pulsar" : gear["Pulsar"]!.toDictionary(), "Special Pulsar" : gear["Special Pulsar"]!.toDictionary(), "Shield" : gear["Shield"]!.toDictionary(), "Attachment 1" : gear["Attachment 1"]!.toDictionary(), "Attachment 2" : gear["Attachment 2"]!.toDictionary()]
        UserDefaults.standard.set(gearDict, forKey:
            "Gear")
        UserDefaults.standard.set(inventoryDict, forKey:
            "Inventory")
        UserDefaults.standard.synchronize()
    }
}
