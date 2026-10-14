//
//  AppDelegate.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/3/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
import CoreData
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private(set) var delveSession: DelveGameSession?
    private var backgroundSave: UIBackgroundTaskIdentifier = .invalid
    private var backgroundSaveOperation: UUID?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // Window creation belongs to the connected scene. Keep this reference for
    // the game's single-window controllers and app-hosted acceptance tests.
    func configureGame(in window: UIWindow) {
        self.window = window
        Constants.w = window.frame.width; Constants.h = window.frame.height
        Constants.uW = window.frame.width * 0.9; Constants.uH = window.frame.height * 0.8
        Constants.jsonDict = loadBundledConstants()
        EnemyEntity.refreshEnemyDictionary()
        if ProcessInfo.processInfo.environment["CUBRISM_LEGACY_TESTING"] == "1" {
            configureLegacyGame(in: window)
            return
        }
        do {
            let session = try DelveBootstrap.load(fileURL: DelveBootstrap.accountURL())
            delveSession = session; Player.delveSession = session
            window.rootViewController = DelveViewController(session: session)
        } catch {
            let controller = UIViewController()
            controller.view.backgroundColor = GameArt.ink
            let label = UILabel(); label.text = "Could not open your saved account.\nYour save has been kept. Retry when storage is available."
            label.numberOfLines = 0; label.textColor = GameArt.ivory; label.textAlignment = .center
            let button = UIButton(type: .system); button.setTitle("Retry loading", for: .normal)
            button.addAction(UIAction { [weak self, weak window] _ in
                if let window = window { self?.configureGame(in: window) }
            }, for: .touchUpInside)
            let stack = UIStackView(arrangedSubviews: [label, button]); stack.axis = .vertical; stack.spacing = 20
            stack.translatesAutoresizingMaskIntoConstraints = false; controller.view.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
                stack.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
            ])
            window.rootViewController = controller
        }
        window.makeKeyAndVisible()
    }

    private func configureLegacyGame(in window: UIWindow) {
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
//        if(Constants.dev == true)
//        {
//            let completedLevel = 50
//            UserDefaults.standard.set(completedLevel, forKey:
//                "LevelCompleted")
//            let level = 45
//            UserDefaults.standard.set(level, forKey: "Level")
//            UserDefaults.standard.synchronize()
//            let experience = 350000
//            UserDefaults.standard.set(experience, forKey: "Experience")
//            UserDefaults.standard.synchronize()
//            Player.level = 45
//            let totaExperience = 350000
//            UserDefaults.standard.set(totaExperience, forKey:
//                "TotalExperience")
//            UserDefaults.standard.synchronize()
//        }
        // Keep a run's balance data stable and usable offline. The old remote
        // endpoint could replace these values and reset health during gameplay.
        Constants.jsonDict = loadBundledConstants()
        EnemyEntity.refreshEnemyDictionary()
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
        if UserDefaults.standard.object(forKey: "equipUpdated") == nil
        {
            Player.balanceEquipment()
            UserDefaults.standard.set(1, forKey: "equipUpdated")
            UserDefaults.standard.synchronize()
        }
        Player.updatePlayer()
        self.window?.rootViewController = view;
        self.window?.makeKeyAndVisible()
        Constants.updateMerchantInventory()
    }

    private func loadBundledConstants() -> [String: Any]? {
        do {
            let file = Bundle.main.url(forResource: "constants", withExtension: "json")
            let data = try Data(contentsOf: file!)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        }
        catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func resetGameControls() {
        Player.entity.component(ofType: PlayerMovementComponent.self)?.joystick.resetInput()
        Player.entity.component(ofType: PlayerShootComponent.self)?.joystick.resetInput()
        #if targetEnvironment(macCatalyst)
        Player.currentScene?.resetKeyboardControls()
        #endif
    }

    func suspendGame() {
        resetGameControls()
        guard let session = delveSession else { return }
        session.suspend()
        (window?.rootViewController as? DelveViewController)?.showPause()
        guard backgroundSave == .invalid else { return }
        let operation = UUID()
        backgroundSaveOperation = operation
        backgroundSave = UIApplication.shared.beginBackgroundTask(withName: "Save Delve") { [weak self] in
            self?.endBackgroundSave(operation)
        }
        Task {
            defer { endBackgroundSave(operation) }
            try? await session.retrySave()
        }
    }

    private func endBackgroundSave(_ operation: UUID) {
        // An expired write may finish after a later background save starts.
        guard backgroundSaveOperation == operation else { return }
        backgroundSaveOperation = nil
        guard backgroundSave != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundSave)
        backgroundSave = .invalid
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
