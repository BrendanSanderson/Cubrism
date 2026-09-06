//
//  HomeViewController.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/3/16.
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
        floorView.modalPresentationStyle = .fullScreen
        
        levelSelectView = LevelSelectCollectionViewController()
        levelSelectView.homeView = self
        levelSelectView.modalPresentationStyle = .fullScreen
        
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
        
        
        scene = HomeScene(size: GameScene.arenaSize)
        skView = SKView(frame: self.view.bounds)
        self.view.backgroundColor = .black
        self.view.addSubview(skView)
        let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(loadingView)
        skView.showsFPS = false
        skView.showsNodeCount = false
        scene.viewController = self
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFit
            
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        skView.bounds = CGRect(origin: .zero, size: GameScene.arenaSize)
        skView.presentScene(scene)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        Player.updateInventory()
        #if targetEnvironment(macCatalyst)
        becomeFirstResponder()
        #endif
        //self.pause
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let available = view.safeAreaLayoutGuide.layoutFrame
        skView.transform = .identity
        if let scene = skView.scene, scene.size.width > 0, scene.size.height > 0 {
            skView.bounds = CGRect(origin: .zero, size: scene.size)
            skView.center = CGPoint(x: available.midX, y: available.midY)
            let scale = min(available.width / scene.size.width, available.height / scene.size.height)
            skView.transform = CGAffineTransform(scaleX: scale, y: scale)
        } else {
            skView.frame = available
        }
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
    @objc func resetHomeViewController(_ notification: Notification){
    
        self.skView.presentScene(nil)
        Player.resetProgress()
        scene = HomeScene(size: GameScene.arenaSize)
        scene.viewController = self
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    @objc func goToFloorViewController(_ notification: Notification){
    // Perform a segue or present ViewController directly
    let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
    self.view.addSubview(loadingView)
        self.view.bringSubviewToFront(loadingView)
    floorView.max = UInt32(6)
    floorView.max = UInt32(4)
    floorView.level = 1
    floorView.needsNewRun = true
    self.present(floorView, animated: false, completion: nil)
    }
    
    @objc func goToLevelSelectCollectionViewController(_ notification: Notification){
        #if targetEnvironment(macCatalyst)
        (skView.scene as? GameScene)?.resetKeyboardControls()
        Player.entity.stopControls()
        #endif
        self.present(levelSelectView, animated: false, completion: nil)
    }
    
    @objc func restartFloorViewController(_ notification: Notification){
        floorView.needsNewRun = true
    self.present(floorView, animated: false, completion: nil)
    }
    
    @objc func goToLevelFloorViewController(_ notification: Notification){
        #if targetEnvironment(macCatalyst)
        (skView.scene as? GameScene)?.resetKeyboardControls()
        Player.entity.stopControls()
        #endif
        
        let loadingView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.view.addSubview(loadingView)
        
        floorView.needsNewRun = true
    self.present(floorView, animated: false, completion: nil)
    }

    #if targetEnvironment(macCatalyst)
    override var canBecomeFirstResponder : Bool {
        return true
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let gameScene = skView.scene as? GameScene {
            gameScene.keyboardPressesBegan(presses)
        }
        else {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let gameScene = skView.scene as? GameScene {
            gameScene.keyboardPressesEnded(presses)
        }
        else {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let gameScene = skView.scene as? GameScene {
            gameScene.keyboardPressesCancelled()
        }
        else {
            super.pressesCancelled(presses, with: event)
        }
    }
    #endif
    
}
