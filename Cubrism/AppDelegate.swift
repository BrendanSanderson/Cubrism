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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let view = HomeViewController()
        //let view = CompletedViewController()
        view.view.multipleTouchEnabled = true
        
        Constants.w = self.window?.frame.width
        Constants.h = self.window?.frame.height
        
        Constants.uW = (self.window?.frame.width)! * 0.9
        Constants.uH = (self.window?.frame.height)! * 0.8
        
        if NSUserDefaults.standardUserDefaults().objectForKey("Level") == nil || NSUserDefaults.standardUserDefaults().objectForKey("Level") as! Int == 0
        {
            let level = 1
            NSUserDefaults.standardUserDefaults().setObject(level, forKey: "Level")
            NSUserDefaults.standardUserDefaults().synchronize()
            Player.level = 1
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("Experience") == nil
        {
            let experience = 0
            NSUserDefaults.standardUserDefaults().setObject(experience, forKey: "Experience")
            NSUserDefaults.standardUserDefaults().synchronize()
            
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("TotalExperience") == nil
        {
            let totaExperience = 0
            NSUserDefaults.standardUserDefaults().setObject(totaExperience, forKey:
                "TotalExperience")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("LevelCompleted") == nil
        {
            let completedLevel = 0
            NSUserDefaults.standardUserDefaults().setObject(completedLevel, forKey:
                "LevelCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("Gear") == nil
        {
            let gear : [String : [String : AnyObject]] = ["Power Core": Equipment(t: "Power Core").toDictionary(), "Armor Core": Equipment(t: "Armor Core").toDictionary(), "Pulsar": Equipment(t:"Pulsar").toDictionary(), "Special Pulsar": Equipment(t: "Special Pulsar").toDictionary(), "Shield": Equipment(t: "Shield").toDictionary(), "Attachment 1": Equipment(t: "Attachment").toDictionary(), "Attachment 2": Equipment(t: "Attachment").toDictionary()]
                NSUserDefaults.standardUserDefaults().setObject(gear, forKey: "Gear")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("Inventory") == nil
        {
            let inventory = [[String : AnyObject]]()
            NSUserDefaults.standardUserDefaults().setObject(inventory, forKey:
                "Inventory")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        Player.gearDict = NSUserDefaults.standardUserDefaults().objectForKey("Gear") as! [String:[String : AnyObject]]
        Player.updateInventory()
        self.window?.rootViewController = view;
        self.window?.makeKeyAndVisible()
        Constants.updateMerchantInventory()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

