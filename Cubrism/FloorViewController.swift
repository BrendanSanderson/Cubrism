//
//  FloorViewController.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/3/16.
//  Copyright (c) 2016 Brendan. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class FloorViewController: UIViewController {
    var length = Int()
    var maze = [[RoomScene]]()
    var start = CGPoint()
    var skView = SKView()
    var scene: RoomScene!
    var level = 1
    var world = 1
    var levelExp = 0
    var rewardsGranted = false
    var needsNewRun = true
    var globalLevel: Int { return (world - 1) * 10 + level }
    var max = UInt32(6)
    var min = UInt32(4)
    var homeView: HomeViewController!
    var enemyPoints = 4
    let arenaSize = GameScene.arenaSize
    
    convenience init(min: UInt32, max: UInt32, level:Int, world:Int)
    {
        self.init()
        self.level = level
        self.world = world
        self.max = max
        self.min = min
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.view.isMultipleTouchEnabled = true
        // Configure the view.
        
//        NSNotificationCenter.defaultCenter().addObserver(
//            self,
//            selector: #selector(FloorViewController.goToRoomScene(_:)),
//            name: "GoToRoomScene",
//            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(FloorViewController.goToHomeViewController(_:)),
            name: NSNotification.Name(rawValue: "GoToHomeViewController"),
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(FloorViewController.goToCompletedViewController(_:)),
            name: NSNotification.Name(rawValue: "GoToCompletedViewController"),
            object: nil)
        
        skView = SKView(frame: self.view.bounds)
        self.view.addSubview(skView)

        skView.showsFPS = false
        skView.showsNodeCount = false
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
    
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard needsNewRun else { return }
        startNewRun()
    }

    func startNewRun() {
        skView.presentScene(nil)
        needsNewRun = false
        levelExp = 0
        rewardsGranted = false
        Player.currentViewController = self
        Player.updatePlayer()
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        skView.bounds = CGRect(origin: .zero, size: arenaSize)
        buildMaze()
        scene = maze[Int(start.x)][Int(start.y)]
        scene.scaleMode = .aspectFit
        scene.startPosition = CGPoint (x: arenaSize.width/2, y: arenaSize.height/2)
        skView.presentScene(scene)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        #if targetEnvironment(macCatalyst)
        becomeFirstResponder()
        #endif
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let available = view.safeAreaLayoutGuide.layoutFrame
        skView.transform = .identity
        if let scene = skView.scene, scene.size.width > 0, scene.size.height > 0 {
            skView.bounds = CGRect(origin: .zero, size: scene.size)
            skView.center = CGPoint(x: available.midX, y: available.midY)
            let scale = Swift.min(available.width / scene.size.width, available.height / scene.size.height)
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
    
    
    func buildMaze (){
        
        length = Int(max > min ? arc4random_uniform(max - min) + min : min)
        start = CGPoint(x: length + 1, y: length + 1)
        var pointer = start
        var scene = RoomScene(size: arenaSize)
        scene.viewController = self
        scene.name = "startRoom"
        maze = Array(repeating: Array(repeating: RoomScene(size: arenaSize), count: (length * 2) + 2), count: length * 2 + 2)
        maze[Int(start.x)][Int(start.y)] = scene
        var oldPointer = pointer
        var direction = 1
        while (length>0)
        {
            direction = Int(arc4random_uniform(4))
            if direction == 0
            {
                pointer = CGPoint(x: pointer.x, y: pointer.y+1)
            }
            else if direction == 2
            {
                pointer = CGPoint(x: pointer.x, y: pointer.y-1)
            }
            else if direction == 1
            {
                pointer = CGPoint(x: pointer.x+1, y: pointer.y)
            }
            else
            {
                pointer = CGPoint(x: pointer.x-1, y: pointer.y)
            }
            if (maze[Int(pointer.x)][Int(pointer.y)].name != "room" && maze[Int(pointer.x)][Int(pointer.y)].name != "startRoom")
            {
                let door = DoorEntity(scene: scene, direction: direction, type: "challenge")
                if (scene.name == "startRoom")
                {
                    door.type = "regular"
                }
                else if (length == 1 )
                {
                    door.type = "bossChallenge"
                }
                door.pointer = pointer
                scene.doors.append(door)
                let oppDirection = oppositeDirection(direction)
                scene = RoomScene(size: arenaSize)
                scene.viewController = self
                scene.name = "room"
                let newDoor = DoorEntity(scene: scene, direction: oppDirection, type: "challenge")
                if (length == 1 )
                {
                    scene.name = "bossRoom"
                    newDoor.type = "bossChallenge"
                }
                newDoor.pointer = oldPointer
                scene.doors.append(newDoor)
                maze[Int(pointer.x)][Int(pointer.y)] = scene
                oldPointer = pointer
                length -= 1
            }
            
        }
    }
    func oppositeDirection(_ direction: Int) -> Int
    {
        if direction == 0
        {
            return 2
        }
        else if direction == 2
        {
            return 0
        }
        else if direction == 1
        {
            return 3
        }
        else
        {
            return 1
        }

    }
    func goToRoomScene(_ notification: Notification){
        // Perform a segue or present ViewController directly
        //[self performSegueWithIdentifier:@"GameOverSegue" sender:self];
        var loc = 0
        var start = CGPoint(x: 100, y: 100)
        for i in 0 ..< scene.doors.count
        {
            if (scene.doors[i].node.name == scene.doorAccessed)
            {
                loc = i
                let door = scene.doors[i]
                start = doorStart(door.direction, position: door.position)
            }
        }
        let newScene = maze[Int(scene.doors[loc].pointer.x)][Int(scene.doors[loc].pointer.y)]
        newScene.scaleMode = .aspectFit
        newScene.startPosition = start
        skView.presentScene(newScene)
        scene = newScene
    }
    func goToRoomScene(){
        // Perform a segue or present ViewController directly
        //[self performSegueWithIdentifier:@"GameOverSegue" sender:self];
        var loc = 0
        var start = CGPoint(x: 100, y: 100)
        for i in 0 ..< scene.doors.count
        {
            if (scene.doors[i].node.name == scene.doorAccessed)
            {
                loc = i
                let door = scene.doors[i]
                start = doorStart(door.direction, position: door.position)
            }
        }
        let newScene = maze[Int(scene.doors[loc].pointer.x)][Int(scene.doors[loc].pointer.y)]
        newScene.scaleMode = .aspectFit
        newScene.startPosition = start
        skView.presentScene(newScene)
        scene = newScene
    }
    
    
    func doorStart (_ direction: Int, position: CGPoint) -> CGPoint
    {
        if direction == 0
        {
            return CGPoint(x: position.x, y: arenaSize.height * 0.05 + 48)
        }
        else if direction == 2
        {
            return CGPoint(x: position.x, y: arenaSize.height*0.95 - 48)
        }
        else if direction == 1
        {
            return CGPoint(x: arenaSize.width * 0.1 + 32, y: position.y)
        }
        else
        {
            return CGPoint(x: arenaSize.width * 0.9 - 32, y: position.y)
        }
    }
    @objc func goToHomeViewController(_ notification: Notification)
    {
        guard Player.currentViewController === self else { return }
        self.skView.presentScene(nil)
        self.dismiss(animated: false, completion: nil)
    }
    @objc func goToCompletedViewController(_ notification: Notification)
    {
        guard Player.currentViewController === self,
              let room = notification.object as? RoomScene, room === scene,
              !rewardsGranted, Player.alive else { return }
        rewardsGranted = true
        self.skView.presentScene(nil)
//        var levelGap = Player.level - self.level
//        var augExp = levelExp
//        if (levelGap > 5)
//        {
//            levelGap = 5
//        }
//        if (levelGap > 1)
//        {
//            augExp = levelExp/(levelGap/2)
//        }
        
        Player.augmentExperience(levelExp)
        
        let drops = self.getDrops()
        
        Player.addDrops(drops)
        
        
        let completeViewController = CompletedViewController()
        completeViewController.expGained = levelExp
        completeViewController.drops = drops
        completeViewController.modalPresentationStyle = .fullScreen
        
        if ((UserDefaults.standard.object(forKey: "LevelCompleted") as! Int) < globalLevel)
        {
            UserDefaults.standard.set(globalLevel, forKey:
                "LevelCompleted")
            UserDefaults.standard.synchronize()

            
        }
        
        self.present(completeViewController, animated: false, completion: nil)
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
    
    func getDrops() -> [Item]
    {
        var d = [Item]()
        let l = globalLevel
        let cubrixels = Int(arc4random_uniform(UInt32((l * 10)))) + 1
        d.append(Item(t: "Cubrixel", q: cubrixels, s: true))
        
        let pt1 = 50 - l
        let pt2 = 50 + l
        let pt3 = l
        let pt4 = Int(Double(l) / 2.0)
        let num = Int(arc4random_uniform(UInt32(100)))
        if num <= (pt1)
        {
            d.append(Equipment(tie: 1, lev: l))
        }
        else if (num <= pt2 + pt1)
        {
            d.append(Equipment(tie: 2, lev: l))
        }
        let num2 = Int(arc4random_uniform(UInt32(100)))
        if num2 <= (pt3)
        {
            d.append(Equipment(tie: 3, lev: l))
        }
        else if (num2 <= pt3 + pt4)
        {
            d.append(Equipment(tie: 4, lev: l))
        }
        return d
    }
    
    
}
