//
//  PopUpNode.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/16/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class VendorPopUpNode: SKNode {
    var mainFrame: SKSpriteNode!
    var gameScene: GameScene!
    var selectedNode: SKSpriteNode!
    let width = 5
    let height = 6
    let size = CGSize(width: 32, height: 32)
    var inv = Array(count: 5, repeatedValue:Array(count: 6, repeatedValue:SKSpriteNode()))
    var powerSquare = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Power Core"]?.type)!), size: CGSize(width: 32, height: 32))
    var armorSquare = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Armor Core"]?.type)!), size: CGSize(width: 32, height: 32))
    var shieldSquare = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Shield"]?.type)!), size: CGSize(width: 32, height: 32))
    var pulsarSquare = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Pulsar"]?.type)!), size: CGSize(width: 32, height: 32))
    var specialSquare = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Special Pulsar"]?.type)!), size: CGSize(width: 32, height: 32))
    var att1Square = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Attachment 1"]?.type)!), size: CGSize(width: 32, height: 32))
    var att2Square = SKSpriteNode(texture: SKTexture(imageNamed: (Player.gear["Attachment 2"]?.type)!), size: CGSize(width: 32, height: 32))
    var labels = [SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode()]
    override init()
    {
        super.init()
    }
    
    init (scene: GameScene, text:String, button1Text: String, button2Text: String)
    {
        super.init()
        self.position = CGPoint(x: scene.frame.width/2, y: scene.frame.height/2)
        mainFrame = SKSpriteNode(imageNamed: "popUp")
        mainFrame.size = CGSize(width: Constants.uW, height: Constants.uH)
        mainFrame.zPosition = 1000
        let centerLine = SKSpriteNode(color: UIColor(red: 8.0/255.0, green: 103/255.0, blue: 111/255.0, alpha: 1), size: CGSize(width: Constants.w * 0.03, height: Constants.uH))
        let leftDividerLine = SKSpriteNode(color: UIColor(red: 8.0/255.0, green: 103/255.0, blue: 111/255.0, alpha: 1), size: CGSize(width: mainFrame.size.width * 0.5, height: mainFrame.size.height * 0.05))
        leftDividerLine.position = CGPoint(x: mainFrame.size.width * -0.25, y: mainFrame.size.height * -0.175)
        centerLine.zPosition = 1001
        leftDividerLine.zPosition = 1001
        
        let inventoryRegion = CGSize(width: mainFrame.size.width * 0.455, height: mainFrame.size.height * 0.90625)
        let inventoryCenter = CGPoint(x: mainFrame.size.width * 0.2425, y: 0)
        let invBotLeft = CGPoint(x: mainFrame.size.width * 0.015, y: mainFrame.size.height * -0.45251)
        let marginWidth = (inventoryRegion.width - 160.0)/6
        let marginHeight = (inventoryRegion.height - 192.0)/7
        let playerCenter = CGPoint(x: mainFrame.size.width * -0.2425, y: mainFrame.size.height * 0.15)
        
      //  scene.paused = true
        
        
        for r in 0 ...  5
        {
            for c in 0 ... 4
            {
                let square = SKSpriteNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
                let posX = invBotLeft.x + marginWidth * CGFloat(c + 1) + size.width/2 + size.width * CGFloat(c)
                let posY = invBotLeft.y + marginHeight * CGFloat(r + 1) + size.height/2 + size.height * CGFloat(r)
                square.position = CGPoint(x: posX, y: posY)
                square.zPosition = 1002
                inv[c][r] = square
                addChild(square)
            }
        }
        for i in 0 ..< Player.inventory.count
        {
            let col = i % 5
            let row = 5 - (i / 5)
            inv[col][row].texture = SKTexture(imageNamed: "\((Player.inventory[i].type))")
            
        }
        
        let playerBackground = SKSpriteNode(texture: SKTexture(imageNamed: "playerIcon"), size: CGSize(width: mainFrame.size.height * 0.55, height: mainFrame.size.height * 0.55))
        playerBackground.position = playerCenter
        playerBackground.zPosition = 1001
        addChild(playerBackground)
        
        powerSquare.zPosition = 1002
        armorSquare.zPosition = 1002
        shieldSquare.zPosition = 1002
        pulsarSquare.zPosition = 1002
        specialSquare.zPosition = 1002
        att1Square.zPosition = 1002
        att2Square.zPosition = 1002
        
        powerSquare.position = playerCenter
        armorSquare.position = CGPoint(x: playerCenter.x -  playerBackground.size.height/4, y: playerCenter.y)
        shieldSquare.position = CGPoint(x: playerCenter.x + playerBackground.size.height/4, y: playerCenter.y)
        pulsarSquare.position = CGPoint(x: playerCenter.x + playerBackground.size.width/2, y: playerCenter.y + pulsarSquare.size.height * 0.75)
        specialSquare.position = CGPoint(x: playerCenter.x + playerBackground.size.width/2, y: playerCenter.y - specialSquare.size.height * 0.75)
        att1Square.position = CGPoint(x: playerCenter.x - playerBackground.size.width/2 + att1Square.size.width/2, y: playerCenter.y - playerBackground.size.height/2 + att1Square.size.height/2)
        att2Square.position = CGPoint(x: playerCenter.x - playerBackground.size.width/2 + att1Square.size.width * 2, y: playerCenter.y - playerBackground.size.height/2 + att1Square.size.height/2)
        
        
        addChild(powerSquare)
        addChild(pulsarSquare)
        addChild(armorSquare)
        addChild(shieldSquare)
        addChild(specialSquare)
        addChild(att1Square)
        addChild(att2Square)

        
        
        
        labels[0] = SKLabelNode(fontNamed: "Arial")
        labels[0].horizontalAlignmentMode = .Center
        labels[0].position = CGPoint(x: mainFrame.size.width * -0.2425, y: mainFrame.size.height * -(0.2 + 0.075))
        labels[0].zPosition = 1002
        labels[0].text = "adf"
        labels[0].fontSize = 24
        addChild(labels[0])
        
        
        for i in 1 ..< labels.count
        {
            //let y = mainFrame.size.height * -(0.2 + 0.075 + (CGFloat(Int(i/3)) * 0.125))
            let y = mainFrame.size.height * -(0.3 + 0.038125 + (CGFloat(Int((i-1)/3)) * 0.07625))
            
            let x1 = (0.14 * CGFloat(i%3))
            let x = mainFrame.size.width * -(0.1025 + x1)
            labels[i] = SKLabelNode(fontNamed: "Arial")
            labels[i].horizontalAlignmentMode = .Center
            labels[i].position = CGPoint(x: x, y: y)
            labels[i].zPosition = 1002
            labels[i].text = "adf"
            labels[i].fontSize = 18
            addChild(labels[i])
        }
        
        
        
        
        
        
        
        
        
        addChild(centerLine)
        addChild(mainFrame)
        addChild(leftDividerLine)
        
        gameScene = scene
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    internal override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let selectedNode = nodeAtPoint(touches.first!.locationInNode(self))
        
    }

    
}
