//
//  CompletedViewController.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/21/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit

class CompletedViewController: UIViewController {
    var expGained = 10
    var level = 0
    var drops = [Item]()
    let font = Constants.font
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
        completeLabel.font = UIFont(name: font, size: 48)
        completeLabel.textAlignment = .center
        completeLabel.textColor = Constants.lightColor
        view.addSubview(completeLabel)
        
        let expGainedLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.3), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel.font = UIFont(name: font, size: 18)
        expGainedLabel.text = String(format: "Experience Gained: %i", expGained)
        expGainedLabel.textAlignment = .center
        expGainedLabel.textColor = Constants.darkColor
        view.addSubview(expGainedLabel)
        
        let expGainedLabel2 = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.4), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel2.font = UIFont(name: font, size: 18)
        expGainedLabel2.text = String(format: "Experience: %i", Player.totalExp)
        expGainedLabel2.textAlignment = .center
        expGainedLabel2.textColor = Constants.darkColor
        view.addSubview(expGainedLabel2)

        
        let expGainedLabel3 = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.1, y: view.frame.height * 0.5), size: CGSize(width: view.frame.width * 0.8, height: view.frame.height * 0.05)))
        expGainedLabel3.font = UIFont(name: font, size: 18)
        expGainedLabel3.text = String(format: "Experience To Next: %i", (Player.expToLevel(Player.level)) - Player.exp)
        expGainedLabel3.textAlignment = .center
        expGainedLabel3.textColor = Constants.darkColor
        view.addSubview(expGainedLabel3)
        
        let expBar = UIProgressView(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.3, y: view.frame.height * 0.625), size: CGSize(width: view.frame.width * 0.4, height: view.frame.height * 0.05)))
        expBar.progress = Float(Player.exp)/Float(Player.expToLevel(Player.level))
        expBar.progressTintColor = Constants.lightColor
        expBar.trackTintColor = Constants.darkColor
        view.addSubview(expBar)
        
        let levelLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.15, y: view.frame.height * 0.6), size: CGSize(width: view.frame.width * 0.15, height: view.frame.height * 0.05)))
        levelLabel.font = UIFont(name: font, size: 18)
        levelLabel.text = String(format: "Level: %i", Player.level)
        levelLabel.textAlignment = .center
        levelLabel.textColor = Constants.darkColor
        view.addSubview(levelLabel)
        
        
        
        let equipmentLabel = UILabel(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.15, y: view.frame.height * 0.725), size: CGSize(width: view.frame.width * 0.15, height: view.frame.height * 0.05)))
        equipmentLabel.font = UIFont(name: font, size: 18)
        equipmentLabel.text = String(format: "Loot:")
        equipmentLabel.textColor = Constants.darkColor
        equipmentLabel.textAlignment = .center
        view.addSubview(equipmentLabel)
        
        let equipment1tier = UIImageView(frame: CGRect(x: view.frame.width * 0.5 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment1tier.image = UIImage(named: "noEquipment")
        view.addSubview(equipment1tier)
        
        let equipment2tier = UIImageView(frame: CGRect(x: view.frame.width * 0.4 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment2tier.image = UIImage(named: "noEquipment")
        view.addSubview(equipment2tier)
        
        let equipment3tier = UIImageView(frame: CGRect(x: view.frame.width * 0.6 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
        equipment3tier.image = UIImage(named: "noEquipment")
        view.addSubview(equipment3tier)
        
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
            if drops[0].isKind(of: Equipment.self)
            {
                equipment1tier.image = UIImage (named: "tier\((drops[0] as! Equipment).tier)")
                if (drops[0] as! Equipment).tier == 0
                {
                    equipment1tier.image = UIImage (named: "tier1")
                }
            }
            equipment1.image = UIImage(named: drops[0].type)
        }
        if (numDrops > 1)
        {
            if drops[1].isKind(of: Equipment.self)
            {
                equipment2tier.image = UIImage (named: "tier\((drops[1] as! Equipment).tier)")
            }
            equipment2.image = UIImage(named: drops[1].type)
        }
        if (numDrops > 2)
        {
            if drops[2].isKind(of: Equipment.self)
            {
                equipment3tier.image = UIImage (named: "tier\((drops[2] as! Equipment).tier)")
            }
            equipment3.image = UIImage(named: drops[2].type)
        }
        
//        let equipment4 = UIImageView(frame: CGRect(x: view.frame.width * 0.3 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
//        equipment4.image = UIImage(named: "noEquipment")
//        view.addSubview(equipment4)
//        
//        let equipment5 = UIImageView(frame: CGRect(x: view.frame.width * 0.7 - view.frame.height * 0.05, y: view.frame.height * 0.7, width: view.frame.height * 0.1, height: view.frame.height * 0.1))
//        equipment5.image = UIImage(named: "noEquipment")
//        view.addSubview(equipment5)
        
        
        
        let button = UIButton(frame: CGRect(origin: CGPoint(x: view.frame.width * 0.32, y: view.frame.height * 0.825), size: CGSize(width: view.frame.width * 0.38, height: view.frame.height * 0.1)))
        button.setTitle("Continue", for: UIControlState())
        button.layer.cornerRadius = 5
        button.backgroundColor = Constants.darkColor
        button.setTitleColor(Constants.lightColor, for: UIControlState())
        button.titleLabel!.font = UIFont(name: font, size: 32)
        view.addSubview(button)
        
        let contineMethod: Selector = NSSelectorFromString("goToHome:")
        button.addTarget(self, action: contineMethod, for: .touchUpInside)

    }
    
    func goToHome(_ sender: UIButton!) {
        self.dismiss(animated: false, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToHomeViewController"), object: self)
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
    
}
