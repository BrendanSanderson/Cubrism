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

class FloorViewController: UIViewController {
    var length = Int()
    var maze = [[RoomScene]]()
    var start = CGPoint()
    var skView = SKView()
    var scene: RoomScene!
    var level = 0
    var world = 0
    var levelExp = 0
    var max = UInt32(6)
    var min = UInt32(4)
    var homeView: HomeViewController!
    var enemyPoints = 4
    
    convenience init(min: UInt32, max: UInt32, level:Int, world:Int)
    {
        self.init()
        self.level = level
        self.max = max
        self.min = min
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "loadingScreen")!)
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
        
        skView = SKView(frame: self.view.frame)
        self.view.addSubview(skView)
        skView.showsFPS = false
        skView.showsNodeCount = true
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
    
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Player.currentViewController = self
        Player.updatePlayer()
        
        buildMaze()
        scene = maze[Int(start.x)][Int(start.y)]
        scene.scaleMode = .resizeFill
        scene.startPosition = CGPoint (x: self.view.frame.width/2, y: self.view.frame.height/2)
        skView.presentScene(scene)
        
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
        
        length = Int(arc4random_uniform(max-min) + min)
        start = CGPoint(x: length + 1, y: length + 1)
        var pointer = start
        var scene = RoomScene()
        scene.viewController = self
        scene.name = "startRoom"
        maze = Array(repeating: Array(repeating: RoomScene(), count: (length * 2) + 2), count: length * 2 + 2)
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
                scene = RoomScene()
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
        newScene.scaleMode = .resizeFill
        newScene.maze = maze
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
        newScene.scaleMode = .resizeFill
        newScene.maze = maze
        newScene.startPosition = start
        skView.presentScene(newScene)
        scene = newScene
    }
    
    
    func doorStart (_ direction: Int, position: CGPoint) -> CGPoint
    {
        if direction == 0
        {
            return CGPoint(x: position.x, y: self.view.frame.height * 0.05 + 48)
        }
        else if direction == 2
        {
            return CGPoint(x: position.x, y: self.view.frame.height*0.95 - 48)
        }
        else if direction == 1
        {
            return CGPoint(x: self.view.frame.width * 0.1 + 32, y: position.y)
        }
        else
        {
            return CGPoint(x: self.view.frame.width * 0.9 - 32, y: position.y)
        }
    }
    func goToHomeViewController(_ notification: Notification)
    {
        self.skView.presentScene(nil)
        self.dismiss(animated: false, completion: nil)
    }
    func goToCompletedViewController(_ notification: Notification)
    {
        self.skView.presentScene(nil)
        var levelGap = Player.level - self.level
        var augExp = levelExp
        if (levelGap > 5)
        {
            levelGap = 5
        }
        if (levelGap > 0)
        {
            augExp = levelExp/(levelGap)
        }
        
        Player.augmentExperience(augExp)
        
        let drops = self.getDrops()
        
        Player.addDrops(drops)
        
        
        let completeViewController = CompletedViewController()
        completeViewController.expGained = augExp
        completeViewController.drops = drops
        
        if ((UserDefaults.standard.object(forKey: "LevelCompleted") as! Int) < level)
        {
            UserDefaults.standard.set(Int(level), forKey:
                "LevelCompleted")
            UserDefaults.standard.synchronize()

            
        }
        
        self.present(completeViewController, animated: false, completion: nil)
    }
    
    func getDrops() -> [Item]
    {
        var d = [Item]()
        let l = level + 10*(world-1)
        let cubrixels = Int(arc4random_uniform(UInt32((l * 10))))
        d.append(Item(t: "Cubrixel", q: cubrixels, s: true))
        
        let pt1 = 50 - l
        let pt2 = 50 + l
        let pt3 = l
        let pt4 = Int(Double(level) / 2.0)
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
