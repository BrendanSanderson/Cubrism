//
//  GameViewController.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/3/16.
//  Copyright (c) 2016 Brendan. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class HomeViewController: UIViewController {
    var skView: SKView!
    var scene: HomeScene!
    var floorView: FloorViewController!
    var levelSelectView: LevelSelectCollectionViewController!
    override func viewDidLoad() {

        super.viewDidLoad()
        if NSUserDefaults.standardUserDefaults().objectForKey("Level") == nil
        {
    
            let level = 0
            let experience = 0
            let totaExperience = 0
            NSUserDefaults.standardUserDefaults().setObject(level, forKey: "Level")
            NSUserDefaults.standardUserDefaults().setObject(experience, forKey: "Experience")
            NSUserDefaults.standardUserDefaults().setObject(totaExperience, forKey: "TotaExperience")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        
        
        floorView = FloorViewController()
        floorView.homeView = self
        
        levelSelectView = LevelSelectCollectionViewController()
        levelSelectView.homeView = self
        
        self.view.multipleTouchEnabled = true
            // Configure the view.
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeViewController.goToFloorViewController(_:)),
            name: "GoToFloorViewController",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeViewController.resetHomeViewController(_:)),
            name: "ResetHomeViewController",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeViewController.restartFloorViewController(_:)),
            name: "RestartFloorViewController",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeViewController.goToLevelSelectCollectionViewController(_:)),
            name: "GoToLevelSelectCollectionViewController",
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(HomeViewController.goToLevelFloorViewController(_:)),
            name: "GoToLevelFloorViewController",
            object: nil)
        
        
        scene = HomeScene()
        skView = SKView(frame: self.view.frame)
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "loadingScreen")!)
        self.view.addSubview(skView)
        let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(loadingView)
        skView.showsFPS = false
        skView.showsNodeCount = true
        scene.viewController = self
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .ResizeFill
            
        
    }
    override func viewDidAppear(animated: Bool) {
        skView.presentScene(scene)
        Player.updateInventory()
        //self.pause
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    func resetHomeViewController(notification: NSNotification){
    
        self.skView.presentScene(nil)
        self.viewDidLoad()
    }
    
    func goToFloorViewController(notification: NSNotification){
    // Perform a segue or present ViewController directly
    let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
    self.view.addSubview(loadingView)
        self.view.bringSubviewToFront(loadingView)
    floorView.max = UInt32(6)
    floorView.max = UInt32(4)
    floorView.level = 1
    self.presentViewController(floorView, animated: false, completion: nil)
    }
    
    func goToLevelSelectCollectionViewController(notification: NSNotification){
        self.presentViewController(levelSelectView, animated: false, completion: nil)
    }
    
    func restartFloorViewController(notification: NSNotification){
        self.presentViewController(floorView, animated: false, completion: nil)
    }
    
    func goToLevelFloorViewController(notification: NSNotification){
        
        let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(loadingView)
        
        self.presentViewController(floorView, animated: false, completion: nil)
    }
    
}
