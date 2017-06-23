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
        if UserDefaults.standard.object(forKey: "Level") == nil
        {
    
            let level = 0
            let experience = 0
            let totaExperience = 0
            UserDefaults.standard.set(level, forKey: "Level")
            UserDefaults.standard.set(experience, forKey: "Experience")
            UserDefaults.standard.set(totaExperience, forKey: "TotaExperience")
            UserDefaults.standard.synchronize()
        }
        
        
        
        floorView = FloorViewController()
        floorView.homeView = self
        
        levelSelectView = LevelSelectCollectionViewController()
        levelSelectView.homeView = self
        
        self.view.isMultipleTouchEnabled = true
            // Configure the view.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.goToFloorViewController(_:)),
            name: NSNotification.Name(rawValue: "GoToFloorViewController"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.resetHomeViewController(_:)),
            name: NSNotification.Name(rawValue: "ResetHomeViewController"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.restartFloorViewController(_:)),
            name: NSNotification.Name(rawValue: "RestartFloorViewController"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.goToLevelSelectCollectionViewController(_:)),
            name: NSNotification.Name(rawValue: "GoToLevelSelectCollectionViewController"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.goToLevelFloorViewController(_:)),
            name: NSNotification.Name(rawValue: "GoToLevelFloorViewController"),
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
        scene.scaleMode = .resizeFill
            
        
    }
    override func viewDidAppear(_ animated: Bool) {
        skView.presentScene(scene)
        Player.updateInventory()
        //self.pause
    }

    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    func resetHomeViewController(_ notification: Notification){
    
        self.skView.presentScene(nil)
        self.viewDidLoad()
    }
    
    func goToFloorViewController(_ notification: Notification){
    // Perform a segue or present ViewController directly
    let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
    self.view.addSubview(loadingView)
        self.view.bringSubview(toFront: loadingView)
    floorView.max = UInt32(6)
    floorView.max = UInt32(4)
    floorView.level = 1
    self.present(floorView, animated: false, completion: nil)
    }
    
    func goToLevelSelectCollectionViewController(_ notification: Notification){
        self.present(levelSelectView, animated: false, completion: nil)
    }
    
    func restartFloorViewController(_ notification: Notification){
        self.present(floorView, animated: false, completion: nil)
    }
    
    func goToLevelFloorViewController(_ notification: Notification){
        
        let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(loadingView)
        
        self.present(floorView, animated: false, completion: nil)
    }
    
}
