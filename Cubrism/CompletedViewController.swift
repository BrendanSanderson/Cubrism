//
//  CompletedViewController.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/21/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit

class CompletedViewController: UIViewController {
    var expGained = 10
    var level = 0
    var drops = [Item]()
    override func viewDidLoad() {
        createGUI()
        
        
    }
    func createGUI()
    {
        let frame = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        frame.image = UIImage(named: "popUp")
        
        view.addSubview(frame)
        
        let completeLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.1), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.20)))
        completeLabel.text = "Floor Complete!"
        completeLabel.font = UIFont(name: "Copperplate-Bold", size: 48)
        completeLabel.textAlignment = .Center
        view.addSubview(completeLabel)
        
        let expGainedLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.3), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel.font = UIFont(name: "Copperplate-Bold", size: 18)
        expGainedLabel.text = String(format: "Experience Gained: %i", expGained)
        expGainedLabel.textAlignment = .Center
        view.addSubview(expGainedLabel)
        
        let expGainedLabel2 = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.4), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel2.font = UIFont(name: "Copperplate-Bold", size: 18)
        expGainedLabel2.text = String(format: "Experience: %i", Player.totalExp)
        expGainedLabel2.textAlignment = .Center
        view.addSubview(expGainedLabel2)

        
        let expGainedLabel3 = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.5), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel3.font = UIFont(name: "Copperplate-Bold", size: 18)
        expGainedLabel3.text = String(format: "Experience To Next: %i", (Player.expToLevel(Player.level)) - Player.exp)
        expGainedLabel3.textAlignment = .Center
        view.addSubview(expGainedLabel3)
        
        let expBar = UIProgressView(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.3, y: view.frame.height * 0.625), size: CGSize(width: view.frame.width * 0.4, height: view.frame.height * 0.05)))
        expBar.progress = Float(Player.exp)/Float(Player.expToLevel(Player.level))
        expBar.progressTintColor = UIColor.orangeColor()
        expBar.trackTintColor = UIColor.blackColor()
        view.addSubview(expBar)
        
        let levelLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.15, y: view.frame.height * 0.6), size: CGSize(width: view.frame.width * 0.15, height: view.frame.height * 0.05)))
        levelLabel.font = UIFont(name: "Copperplate-Bold", size: 18)
        levelLabel.text = String(format: "Level: %i", Player.level)
        levelLabel.textAlignment = .Center
        view.addSubview(levelLabel)
        
        
        
        let equipmentLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.15, y: view.frame.height * 0.725), size: CGSize(width: view.frame.width * 0.15, height: view.frame.height * 0.05)))
        equipmentLabel.font = UIFont(name: "Copperplate-Bold", size: 18)
        equipmentLabel.text = String(format: "Loot:")
        equipmentLabel.textAlignment = .Center
        view.addSubview(equipmentLabel)
        
        let equipment1 = UIImageView(frame: CGRect(x: view.frame.width * 0.5 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment1.image = UIImage(named: "noEquipment")
        view.addSubview(equipment1)
        
        let equipment2 = UIImageView(frame: CGRect(x: view.frame.width * 0.4 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment2.image = UIImage(named: "noEquipment")
        view.addSubview(equipment2)
        
        let equipment3 = UIImageView(frame: CGRect(x: view.frame.width * 0.6 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment3.image = UIImage(named: "noEquipment")
        view.addSubview(equipment3)
        
        let numDrops = drops.count
        if (numDrops > 0)
        {
            equipment1.image = UIImage(named: drops[0].type)
        }
        if (numDrops > 1)
        {
            equipment2.image = UIImage(named: drops[1].type)
        }
        if (numDrops > 2)
        {
            equipment2.image = UIImage(named: drops[2].type)
        }
        
//        let equipment4 = UIImageView(frame: CGRect(x: view.frame.width * 0.3 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
//        equipment4.image = UIImage(named: "noEquipment")
//        view.addSubview(equipment4)
//        
//        let equipment5 = UIImageView(frame: CGRect(x: view.frame.width * 0.7 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
//        equipment5.image = UIImage(named: "noEquipment")
//        view.addSubview(equipment5)
        
        
        
        let button = UIButton(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.3, y: view.frame.height * 0.825), size: CGSize(width: view.frame.width * 0.4, height: view.frame.height * 0.1)))
        button.setTitle("Continue", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.titleLabel!.font = UIFont(name: "Copperplate-Bold", size: 32)
        view.addSubview(button)
        
        let contineMethod: Selector = NSSelectorFromString("goToHome:")
        button.addTarget(self, action: contineMethod, forControlEvents: .TouchUpInside)

    }
    
    func goToHome(sender: UIButton!) {
        self.dismissViewControllerAnimated(false, completion: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("GoToHomeViewController", object: self)
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
    
}
