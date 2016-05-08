//
//  PopUpNode.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/16/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class PopUpNode: SKNode {
    var mainFrame: SKSpriteNode!
    var gameScene: GameScene!
    var label: UILabel!
    var button1: UIButton!
    var button2: UIButton!
    override init()
    {
        super.init()
    }
    
    init (scene: GameScene, text:String, button1Text: String, button2Text: String)
    {
        super.init()
        self.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height/2)
        //mainFrame = SKSpriteNode(texture: SKTexture(imageNamed: "popUp"), size: CGSize(width: scene.frame.width * 0.8, height: scene.frame.height * 0.7))
        mainFrame = SKSpriteNode(imageNamed: "popUp")
        mainFrame.zPosition = 1000
        label = UILabel(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/2), y: scene.size.height * 0.33 - 25, width: mainFrame.size.width, height: 50))
        button1 = UIButton(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/3), y: scene.size.height * 0.66, width: mainFrame.size.width/6, height: scene.size.height * 0.1))
        button2 = UIButton(frame: CGRect(x: scene.size.width * 0.5 + (mainFrame.size.width/6), y: scene.size.height * 0.66, width: mainFrame.size.width/6, height: scene.size.height * 0.1))
        button1.layer.cornerRadius = 5
        button2.layer.cornerRadius = 5
//        button1.layer.borderWidth = 1
//        button1.layer.borderColor = UIColor.blackColor().CGColor
//        button2.layer.borderWidth = 3
//        button2.layer.borderColor = UIColor.blackColor().CGColor
        addChild(mainFrame)
        gameScene = scene
        scene.paused = true
//        button1.titleLabel!.textAlignment = .Center
//        button2.titleLabel!.textAlignment = .Center
        button1.backgroundColor = UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1)
       button2.backgroundColor = UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1)
        button1.setTitle(button1Text, forState: .Normal)
        button2.setTitle(button2Text, forState: .Normal)
        button1.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button2.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//        button1.backgroundColor = UIColor.redColor()
//        button2.backgroundColor = UIColor.redColor()
        label.textAlignment = .Center
        label.text = text
        button1.titleLabel!.font = UIFont(name: "Copperplate-Bold", size: 18)
        button2.titleLabel!.font = UIFont(name: "Copperplate-Bold", size: 18)
        label.font = UIFont(name: "Copperplate-Bold", size: 32)
        
        scene.view?.addSubview(button1)
        scene.view?.addSubview(button2)
        scene.view?.addSubview(label)
        
        let b1Method: Selector = NSSelectorFromString(String(format: "%@:", button1Text.lowercaseString))
        let b2Method: Selector = NSSelectorFromString(String(format: "%@:", button2Text.lowercaseString))
        button1.addTarget(self, action: b1Method, forControlEvents: .TouchUpInside)
        button2.addTarget(self, action: b2Method, forControlEvents: .TouchUpInside)
        
        let expLabel = UILabel(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/2), y: scene.size.height * 0.4, width: mainFrame.size.width, height: scene.size.height * 0.1))
        
        let expLeftLabel = UILabel(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/2), y: scene.size.height * 0.45, width: mainFrame.size.width, height: scene.size.height * 0.1))
        expLabel.textAlignment = .Center
        expLeftLabel.textAlignment = .Center
        if (text == "You are Dead.")
        {
            expLabel.text = String(format: "Experence Gained: %i", Player.expGained)
        }
        else
        {
            expLabel.text = String(format: "Total Exp: %i", (Player.totalExp))
        }
        
        expLeftLabel.text = String(format: "Exp To Level: %i", (Player.expToLevel(Player.level) - Player.exp))
        expLeftLabel.font = UIFont(name: "Copperplate-Bold", size: 20)
        expLabel.font = UIFont(name: "Copperplate-Bold", size: 20)
        
        scene.view?.addSubview(expLabel)
        scene.view?.addSubview(expLeftLabel)
        
        let expBar = UIProgressView(frame: CGRect(origin: CGPoint(x: scene.size.width * 0.35, y: scene.frame.height * 0.55), size: CGSize(width: scene.size.width * 0.3, height: mainFrame.frame.height * 0.1)))
        expBar.progress = Float(Player.exp)/Float(Player.expToLevel(Player.level))
        expBar.progressTintColor = UIColor.orangeColor()
        expBar.trackTintColor = UIColor.blackColor()
        scene.view!.addSubview(expBar)
        
        
        let levelLabel = UILabel(frame: CGRect(origin: CGPoint(x: scene.frame.width * 0.24, y: scene.frame.height * 0.525), size: CGSize(width: scene.frame.width * 0.1, height: scene.frame.height * 0.05)))
        levelLabel.font = UIFont(name: "Copperplate-Bold", size: 18)
        levelLabel.text = String(format: "%i", Player.level)
        levelLabel.textAlignment = .Right
        scene.view!.addSubview(levelLabel)
        
    }
    
    func play(sender: UIButton!) {
        remove()
        gameScene.paused = false
        
        
    }
    
    func quit(sender: UIButton!) {
        remove()
        
        gameScene.addChild(PopUpNode(scene: gameScene, text: "Are You Sure?", button1Text: "Yes", button2Text: "No"))
        
    }
    func no(sender: UIButton!) {
        remove()
        
        gameScene.addChild(PopUpNode(scene: gameScene, text: "Paused", button1Text: "Play", button2Text: "Quit"))
        
    }
    
    func yes(sender: UIButton!) {
        remove()
        if (gameScene.isKindOfClass(HomeScene))
        {
            gameScene.paused = false
            NSNotificationCenter.defaultCenter().postNotificationName("ResetHomeViewController", object: self)
            let level = 1
            NSUserDefaults.standardUserDefaults().setObject(level, forKey: "Level")
            let experience = 0
            NSUserDefaults.standardUserDefaults().setObject(experience, forKey: "Experience")
            let totaExperience = 0
            NSUserDefaults.standardUserDefaults().setObject(totaExperience, forKey:
                    "TotalExperience")
            NSUserDefaults.standardUserDefaults().setObject(0, forKey:
                "LevelCompleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        
        }
        else
        {
        NSNotificationCenter.defaultCenter().postNotificationName("GoToHomeViewController", object: self)
        }
        
    }
    
    func remove()
    {

        for (var i = (gameScene.view?.subviews.count)! - 1; i >= 0; i -= 1) {
            if ((gameScene.view?.subviews[i].isKindOfClass(UIButton)) == true)
            {
                gameScene.view!.subviews[i].removeFromSuperview()
            }
            else if ((gameScene.view?.subviews[i].isKindOfClass(UILabel)) == true)
            {
                if (gameScene.view?.subviews[i] as! UILabel).text != String(format: "%i", Player.level) || (gameScene.view?.subviews[i] as! UILabel).textColor != UIColor.whiteColor()
                {
                    gameScene.view!.subviews[i].removeFromSuperview()
                }
            }
            else if ((gameScene.view?.subviews[i].isKindOfClass(UIProgressView)) == true)
            {
                gameScene.view!.subviews[i].removeFromSuperview()
            }
        }
        self.mainFrame.removeFromParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func retry(sender: UIButton!) {
        remove()
        (scene as! RoomScene).viewController.max = (scene as! RoomScene).viewController.max
        (scene as! RoomScene).viewController.min = (scene as! RoomScene).viewController.min
        (scene as! RoomScene).viewController.level = (scene as! RoomScene).viewController.level
        
        (scene as! RoomScene).viewController.dismissViewControllerAnimated(false, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("RestartFloorViewController", object: nil)
           
    }
    
    func leave(sender: UIButton!) {
        remove()
        if (gameScene.isKindOfClass(HomeScene))
        {
            gameScene.paused = false
            NSNotificationCenter.defaultCenter().postNotificationName("ResetHomeViewController", object: self)
        }
        else
        {
            NSNotificationCenter.defaultCenter().postNotificationName("GoToHomeViewController", object: self)
        }
    }
    
    
}
