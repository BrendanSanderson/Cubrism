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
        scene.isPaused = true
//        button1.titleLabel!.textAlignment = .Center
//        button2.titleLabel!.textAlignment = .Center
        button1.backgroundColor = UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1)
       button2.backgroundColor = UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1)
        button1.setTitle(button1Text, for: UIControlState())
        button2.setTitle(button2Text, for: UIControlState())
        button1.setTitleColor(UIColor.white, for: UIControlState())
        button2.setTitleColor(UIColor.white, for: UIControlState())
//        button1.backgroundColor = UIColor.redColor()
//        button2.backgroundColor = UIColor.redColor()
        label.textAlignment = .center
        label.text = text
        button1.titleLabel!.font = UIFont(name: "Copperplate-Bold", size: 18)
        button2.titleLabel!.font = UIFont(name: "Copperplate-Bold", size: 18)
        label.font = UIFont(name: "Copperplate-Bold", size: 32)
        
        scene.view?.addSubview(button1)
        scene.view?.addSubview(button2)
        scene.view?.addSubview(label)
        
        let b1Method: Selector = NSSelectorFromString(String(format: "%@:", button1Text.lowercased()))
        let b2Method: Selector = NSSelectorFromString(String(format: "%@:", button2Text.lowercased()))
        button1.addTarget(self, action: b1Method, for: .touchUpInside)
        button2.addTarget(self, action: b2Method, for: .touchUpInside)
        
        let expLabel = UILabel(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/2), y: scene.size.height * 0.4, width: mainFrame.size.width, height: scene.size.height * 0.1))
        
        let expLeftLabel = UILabel(frame: CGRect(x: scene.size.width * 0.5 - (mainFrame.size.width/2), y: scene.size.height * 0.45, width: mainFrame.size.width, height: scene.size.height * 0.1))
        expLabel.textAlignment = .center
        expLeftLabel.textAlignment = .center
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
        expBar.progressTintColor = UIColor.orange
        expBar.trackTintColor = UIColor.black
        scene.view!.addSubview(expBar)
        
        
        let levelLabel = UILabel(frame: CGRect(origin: CGPoint(x: scene.frame.width * 0.24, y: scene.frame.height * 0.525), size: CGSize(width: scene.frame.width * 0.1, height: scene.frame.height * 0.05)))
        levelLabel.font = UIFont(name: "Copperplate-Bold", size: 18)
        levelLabel.text = String(format: "%i", Player.level)
        levelLabel.textAlignment = .right
        scene.view!.addSubview(levelLabel)
        
    }
    
    func play(_ sender: UIButton!) {
        remove()
        gameScene.isPaused = false
        
        
    }
    
    func quit(_ sender: UIButton!) {
        remove()
        
        gameScene.addChild(PopUpNode(scene: gameScene, text: "Are You Sure?", button1Text: "Yes", button2Text: "No"))
        
    }
    func no(_ sender: UIButton!) {
        remove()
        
        gameScene.addChild(PopUpNode(scene: gameScene, text: "Paused", button1Text: "Play", button2Text: "Quit"))
        
    }
    
    func yes(_ sender: UIButton!) {
        remove()
        if (gameScene.isKind(of: HomeScene.self))
        {
            gameScene.isPaused = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetHomeViewController"), object: self)
            let level = 1
            UserDefaults.standard.set(level, forKey: "Level")
            let experience = 0
            UserDefaults.standard.set(experience, forKey: "Experience")
            let totaExperience = 0
            UserDefaults.standard.set(totaExperience, forKey:
                    "TotalExperience")
            UserDefaults.standard.set(0, forKey:
                "LevelCompleted")
            UserDefaults.standard.removeObject(forKey: "Gear")
            UserDefaults.standard.removeObject(forKey: "Inventory")
            UserDefaults.standard.synchronize()
        
        }
        else
        {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToHomeViewController"), object: self)
        }
        
    }
    
    func remove()
    {

        for i in (0...((gameScene.view?.subviews.count)!-1)).reversed() {
            if ((gameScene.view?.subviews[i].isKind(of: UIButton.self)) == true)
            {
                gameScene.view!.subviews[i].removeFromSuperview()
            }
            else if ((gameScene.view?.subviews[i].isKind(of: UILabel.self)) == true)
            {
                if (gameScene.view?.subviews[i] as! UILabel).text != String(format: "%i", Player.level) || (gameScene.view?.subviews[i] as! UILabel).textColor != UIColor.white
                {
                    gameScene.view!.subviews[i].removeFromSuperview()
                }
            }
            else if ((gameScene.view?.subviews[i].isKind(of: UIProgressView.self)) == true)
            {
                gameScene.view!.subviews[i].removeFromSuperview()
            }
        }
        self.mainFrame.removeFromParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func retry(_ sender: UIButton!) {
        remove()
        (scene as! RoomScene).viewController.max = (scene as! RoomScene).viewController.max
        (scene as! RoomScene).viewController.min = (scene as! RoomScene).viewController.min
        (scene as! RoomScene).viewController.level = (scene as! RoomScene).viewController.level
        
        (scene as! RoomScene).viewController.dismiss(animated: false, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RestartFloorViewController"), object: nil)
           
    }
    
    func leave(_ sender: UIButton!) {
        remove()
        if (gameScene.isKind(of: HomeScene.self))
        {
            gameScene.isPaused = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetHomeViewController"), object: self)
        }
        else
        {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToHomeViewController"), object: self)
        }
    }
    
    
}
