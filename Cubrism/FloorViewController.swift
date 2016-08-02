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
    var levelExp = 0
    var max = UInt32(6)
    var min = UInt32(4)
    var homeView: HomeViewController!
    var enemyPoints = 4
    
    convenience init(min: UInt32, max: UInt32, level:Int)
    {
        self.init()
        self.level = level
        self.max = max
        self.min = min
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "loadingScreen")!)
        self.view.multipleTouchEnabled = true
        // Configure the view.
        
//        NSNotificationCenter.defaultCenter().addObserver(
//            self,
//            selector: #selector(FloorViewController.goToRoomScene(_:)),
//            name: "GoToRoomScene",
//            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(FloorViewController.goToHomeViewController(_:)),
            name: "GoToHomeViewController",
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(FloorViewController.goToCompletedViewController(_:)),
            name: "GoToCompletedViewController",
            object: nil)
        
        skView = SKView(frame: self.view.frame)
        self.view.addSubview(skView)
        skView.showsFPS = false
        skView.showsNodeCount = true
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
    
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Player.currentViewController = self
        Player.updatePlayer()
        
        buildMaze()
        scene = maze[Int(start.x)][Int(start.y)]
        scene.scaleMode = .ResizeFill
        scene.startPosition = CGPoint (x: self.view.frame.width/2, y: self.view.frame.height/2)
        skView.presentScene(scene)
        
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
    
    
    func buildMaze (){
        
        length = Int(arc4random_uniform(max-min) + min)
        start = CGPoint(x: length + 1, y: length + 1)
        var pointer = start
        var scene = RoomScene()
        scene.viewController = self
        scene.name = "startRoom"
        maze = Array(count:length * 2 + 2, repeatedValue:Array(count:(length * 2) + 2, repeatedValue:RoomScene()))
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
    func oppositeDirection(direction: Int) -> Int
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
    func goToRoomScene(notification: NSNotification){
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
        newScene.scaleMode = .ResizeFill
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
        newScene.scaleMode = .ResizeFill
        newScene.maze = maze
        newScene.startPosition = start
        skView.presentScene(newScene)
        scene = newScene
    }
    
    
    func doorStart (direction: Int, position: CGPoint) -> CGPoint
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
    func goToHomeViewController(notification: NSNotification)
    {
        self.skView.presentScene(nil)
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    func goToCompletedViewController(notification: NSNotification)
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
        
        if ((NSUserDefaults.standardUserDefaults().objectForKey("LevelCompleted") as! Int) < level)
        {
            NSUserDefaults.standardUserDefaults().setObject(Int(level), forKey:
                "LevelCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()

            
        }
        
        self.presentViewController(completeViewController, animated: false, completion: nil)
    }
    
    func getDrops() -> [Item]
    {
        var d = [Item]()
        let cubrixels = Int(arc4random_uniform(UInt32((level * 10))))
        d.append(Item(t: "Cubrixel", q: cubrixels, s: true))
        
        let pt1 = 50 - level
        let pt2 = 50 + level
        let pt3 = level
        let pt4 = Int(Double(level) / 2.0)
        let num = Int(arc4random_uniform(UInt32(100)))
        if num <= (pt1)
        {
            d.append(Equipment(tie: 1, lev: level))
        }
        else if (num <= pt2 + pt1)
        {
            d.append(Equipment(tie: 2, lev: level))
        }
        let num2 = Int(arc4random_uniform(UInt32(100)))
        if num2 <= (pt3)
        {
            d.append(Equipment(tie: 3, lev: level))
        }
        else if (num2 <= pt3 + pt4)
        {
            d.append(Equipment(tie: 4, lev: level))
        }
        return d
    }
    
    
}
