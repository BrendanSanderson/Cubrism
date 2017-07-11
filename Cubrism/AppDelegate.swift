//
//  AppDelegate.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/3/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
import CoreData
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let view = HomeViewController()
        //let view = CompletedViewController()
        view.view.isMultipleTouchEnabled = true
        
        Constants.w = self.window?.frame.width
        Constants.h = self.window?.frame.height
        
        Constants.uW = (self.window?.frame.width)! * 0.9
        Constants.uH = (self.window?.frame.height)! * 0.8
        
        if UserDefaults.standard.object(forKey: "Level") == nil || UserDefaults.standard.object(forKey: "Level") as! Int == 0
        {
            let level = 1
            UserDefaults.standard.set(level, forKey: "Level")
            UserDefaults.standard.synchronize()
            Player.level = 1
        }
        if UserDefaults.standard.object(forKey: "Experience") == nil
        {
            let experience = 0
            UserDefaults.standard.set(experience, forKey: "Experience")
            UserDefaults.standard.synchronize()
            
        }
        if UserDefaults.standard.object(forKey: "TotalExperience") == nil
        {
            let totaExperience = 0
            UserDefaults.standard.set(totaExperience, forKey:
                "TotalExperience")
            UserDefaults.standard.synchronize()
        }
        if UserDefaults.standard.object(forKey: "LevelCompleted") == nil
        {
            let completedLevel = 0
            UserDefaults.standard.set(completedLevel, forKey:
                "LevelCompleted")
            UserDefaults.standard.synchronize()
        }
        if(Constants.dev == true)
        {
            let completedLevel = 50
            UserDefaults.standard.set(completedLevel, forKey:
                "LevelCompleted")
            let level = 45
            UserDefaults.standard.set(level, forKey: "Level")
            UserDefaults.standard.synchronize()
            let experience = 350000
            UserDefaults.standard.set(experience, forKey: "Experience")
            UserDefaults.standard.synchronize()
            Player.level = 45
            let totaExperience = 350000
            UserDefaults.standard.set(totaExperience, forKey:
                "TotalExperience")
            UserDefaults.standard.synchronize()
        }
        do {
            let file = Bundle.main.url(forResource: "constants", withExtension: "json")
            let data = try Data(contentsOf: file!)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let jsonDict = json as? [String: Any]
            UserDefaults.standard.set(jsonDict, forKey: "jsonConstants")
            UserDefaults.standard.synchronize()
            
        }
        catch {
            print(error.localizedDescription)
        }
        
        if UserDefaults.standard.object(forKey: "Gear") == nil
        {
            let gear : [String : [String : AnyObject]] = ["Power Core": Equipment(t: "Power Core").toDictionary(), "Armor Core": Equipment(t: "Armor Core").toDictionary(), "Pulsar": Equipment(t:"Pulsar").toDictionary(), "Special Pulsar": Equipment(t: "Special Pulsar").toDictionary(), "Shield": Equipment(t: "Shield").toDictionary(), "Attachment 1": Equipment(t: "Attachment").toDictionary(), "Attachment 2": Equipment(t: "Attachment").toDictionary()]
                UserDefaults.standard.set(gear, forKey: "Gear")
            UserDefaults.standard.synchronize()
        }
        if UserDefaults.standard.object(forKey: "Inventory") == nil
        {
            let inventory = [[String : AnyObject]]()
            UserDefaults.standard.set(inventory, forKey:
                "Inventory")
            UserDefaults.standard.synchronize()
        }
        Player.gearDict = UserDefaults.standard.object(forKey: "Gear") as! [String:[String : AnyObject]]
        Player.readConstants()
        Player.updateInventory()
        Player.updateEquipment()
        Player.updatePlayer()
        self.window?.rootViewController = view;
        self.window?.makeKeyAndVisible()
        Constants.updateMerchantInventory()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

