//
//  PopUpNode.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/16/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit
class VendorPopUpNode: SKNode
{
    var mainFrame: SKSpriteNode!
    var selectedNode: ItemNode!
    var labels = [SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode(), SKLabelNode()]
    
    func updateLabels()
    {
        if (selectedNode != nil)
        {
            labels[0].text = "\(selectedNode.item.type!)"
            if selectedNode.item.isKind(of: Equipment.self)
            {
                let equip = (selectedNode.item as? Equipment)!
                labels[0].text = "\(selectedNode.item.type!) Lvl: \(equip.level)"
                var stats = [String]()
                if round(10 * equip.attackPower) / 10 > 0
                {
                    stats.append("Att: \(Constants.forTailingZero(round(equip.attackPower)))")
                }
                if (round(10 * equip.defence) / 10) > 0
                {
                    stats.append("Def: \(Constants.forTailingZero(round(equip.defence)))")
                }
                if round(10 * equip.health) / 10 > 0
                {
                    stats.append("Hlth: \(Constants.forTailingZero(round(equip.health)))")
                }
                if round(10 * equip.shield) / 10 > 0
                {
                    stats.append("Shd: \(Constants.forTailingZero(round(equip.shield)))")
                }
                if round(10 * equip.shieldRegen) / 10 > 0
                {
                    stats.append("ShdR: \(Constants.forTailingZero(round(equip.shieldRegen)))")
                }
                if round(10 * equip.attackSpeed) / 10 > 0
                {
                    stats.append("AttS: \(Constants.forTailingZero(round(equip.attackSpeed)))")
                }
                for i in 0 ..< stats.count
                {
                    labels[i+1].text = stats[i]
                }
                for i in stats.count ... 5
                {
                    labels[i+1].text = ""
                }
                
            }
            else
            {
                if let q = selectedNode.quantity.text as String! {labels[1].text = "x \(q)"}
                labels[2].text = ""
                labels[3].text = ""
                labels[4].text = ""
                labels[5].text = ""
                labels[6].text = ""
            }
        }
        else
        {
            labels[0].text = "No Selection"
            labels[1].text = ""
            labels[2].text = ""
            labels[3].text = ""
            labels[4].text = ""
            labels[5].text = ""
            labels[6].text = ""
        }
    }
    func setupLabels()
    {
        labels[0] = SKLabelNode(fontNamed: "Arial")
        labels[0].horizontalAlignmentMode = .center
        labels[0].position = CGPoint(x: mainFrame.size.width * -0.2425, y: mainFrame.size.height * -(0.2 + 0.075))
        labels[0].zPosition = 1002
        labels[0].text = "No Selection"
        labels[0].fontSize = 24
        addChild(labels[0])
        
        
        for i in 1 ..< labels.count
        {
            //let y = mainFrame.size.height * -(0.2 + 0.075 + (CGFloat(Int(i/3)) * 0.125))
            let y = mainFrame.size.height * -(0.3 + 0.038125 + (CGFloat(Int((i-1)/3)) * 0.07625))
            
            let x1 = (0.14 * CGFloat(i%3))
            let x = mainFrame.size.width * -(0.1025 + x1)
            labels[i] = SKLabelNode(fontNamed: "Arial")
            labels[i].horizontalAlignmentMode = .center
            labels[i].position = CGPoint(x: x, y: y)
            labels[i].zPosition = 1002
            labels[i].text = ""
            labels[i].fontSize = 18
            addChild(labels[i])
        }
        
    }

}
class BankPopUpNode: VendorPopUpNode {
    var gameScene: GameScene!
    var selectedSquare = SKSpriteNode(color: UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1), size: CGSize(width: 40, height: 40))
    let width = 5
    let height = 6
    let size = CGSize(width: 32, height: 32)
    var inv = Array(repeating: Array(repeating: SKSpriteNode(), count: 6), count: 5)
    var powerSquare = ItemNode(i: Player.gear["Power Core"]!)
    var armorSquare = ItemNode(i: Player.gear["Armor Core"]!)
    var shieldSquare = ItemNode(i: Player.gear["Shield"]!)
    var pulsarSquare = ItemNode(i: Player.gear["Pulsar"]!)
    var specialSquare = ItemNode(i: Player.gear["Special Pulsar"]!)
    var att1Square =  ItemNode(i: Player.gear["Attachment 1"]!)
    var att2Square =  ItemNode(i: Player.gear["Attachment 2"]!)
    override init()
    {
        super.init()
    }
    
    init (scene: GameScene)
    {
        super.init()
        self.isUserInteractionEnabled = true
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
        selectedSquare.zPosition = 1002
        
        for r in 0 ...  5
        {
            for c in 0 ... 4
            {
                let square = SelectNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
                let posX = invBotLeft.x + marginWidth * CGFloat(c + 1) + size.width/2 + size.width * CGFloat(c)
                let posY = invBotLeft.y + marginHeight * CGFloat(r + 1) + size.height/2 + size.height * CGFloat(r)
                square.position = CGPoint(x: posX, y: posY)
                square.zPosition = 1003
                inv[c][r] = square
                addChild(square)
            }
        }
        for i in 0 ..< Player.inventory.count
        {
            let col = i % 5
            let row = 5 - (i / 5)
            let temp = inv[col][row]
            inv[col][row] = ItemNode(i: Player.inventory[i])
            inv[col][row].position = temp.position
            inv[col][row].zPosition = temp.zPosition
            temp.removeFromParent()
            addChild(inv[col][row])
        }
        
        let playerBackground = SKSpriteNode(texture: SKTexture(imageNamed: "playerIcon"), size: CGSize(width: mainFrame.size.height * 0.55, height: mainFrame.size.height * 0.55))
        playerBackground.position = playerCenter
        playerBackground.zPosition = 1001
        addChild(playerBackground)
        
        powerSquare.zPosition = 1003
        armorSquare.zPosition = 1003
        shieldSquare.zPosition = 1003
        pulsarSquare.zPosition = 1003
        specialSquare.zPosition = 1003
        att1Square.zPosition = 1003
        att2Square.zPosition = 1003
        
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

        self.setupLabels()
        self.updateLabels()
        
        
        
        
        
        addChild(centerLine)
        addChild(mainFrame)
        addChild(leftDividerLine)
        
        gameScene = scene
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let selNode = atPoint(touches.first!.location(in: self))
        if selNode.isKind(of: ItemNode.self)
        {
            if selectedNode == nil || selNode.position == selectedNode.position
            {
                selectedNode = selNode as? ItemNode
                selectedSquare.position = selNode.position
                if selectedSquare.parent == nil
                {
                    addChild(selectedSquare)
                }
                self.updateLabels()
            }
            else
            {
                if selNode.position.x < 0 && selectedNode.position.x > 0.0
                {
                    if (selNode as? ItemNode)!.item.type == selectedNode.item.type
                    {
                        let tempPosition = selNode.position
                        selNode.position = selectedNode.position
                        selectedNode.position = tempPosition
                        selectedSquare.position = selectedNode.position
                        
                        
                        if selectedNode.item.type == "Attachment"
                        {
                            if ((selNode as? ItemNode)!.item as? Equipment) == Player.gear["Attachment 1"]
                            {
                                Player.gear["Attachment 1"] = selectedNode.item as? Equipment
                            }
                            else
                            {
                                Player.gear["Attachment 2"] = selectedNode.item as? Equipment
                            }
                        }
                        else
                        {
                            Player.gear[selectedNode.item.type] = selectedNode.item as? Equipment
                        }
                        let i = Player.inventory.index(of: selectedNode.item)!
                        Player.inventory[i] = (selNode as? ItemNode)!.item
                        
                        
                    }
                    else if selectedNode.item.type != (selNode as! ItemNode).item.type
                    {
                        selectedNode = nil
                        self.updateLabels()
                        if selectedSquare.parent != nil
                        {
                            selectedSquare.removeFromParent()
                        }
                    }
                }
                else if selNode.position.x > 0 && selectedNode.position.x > 0
                {
                    let tempPosition = selNode.position
                    selNode.position = selectedNode.position
                    selectedNode.position = tempPosition
                    selectedSquare.position = selectedNode.position
                }
                else
                {
                    selectedNode = nil
                    self.updateLabels()
                    if selectedSquare.parent != nil
                    {
                        selectedSquare.removeFromParent()
                    }
                }
            }
            
        }
        else if selNode.isKind(of: SelectNode.self)
        {
            selectedNode = nil
            self.updateLabels()
            if selectedSquare.parent != nil
            {
                selectedSquare.removeFromParent()
            }
        }
    }
}
class ShopPopUpNode: VendorPopUpNode {
        var gameScene: GameScene!
        var selectedSquare = SKSpriteNode(color: UIColor(red: 8.0/255.0, green: 103.0/255.0, blue: 111.0/255.0, alpha: 1), size: CGSize(width: 40, height: 40))
        let width = 5
        let height = 6
        let vWidth = 5
        let vHeight = 3
        let size = CGSize(width: 32, height: 32)
        var inv = Array(repeating: Array(repeating: SKSpriteNode(), count: 6), count: 5)
        var mInv = Array(repeating: Array(repeating: SKSpriteNode(), count: 3), count: 5)
        let vendorButton = SellNode(s: CGSize(width: 72, height: 36))
        override init()
        {
            super.init()
        }
        
        init (scene: GameScene)
        {
            super.init()
            self.isUserInteractionEnabled = true
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
            let merchantCenter = CGPoint(x: mainFrame.size.width * -0.2425, y: mainFrame.size.height * 0.15)
            
            //  scene.paused = true
            selectedSquare.zPosition = 1002
            
            for r in 0 ...  5
            {
                for c in 0 ... 4
                {
                    let square = SelectNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
                    let posX = invBotLeft.x + marginWidth * CGFloat(c + 1) + size.width/2 + size.width * CGFloat(c)
                    let posY = invBotLeft.y + marginHeight * CGFloat(r + 1) + size.height/2 + size.height * CGFloat(r)
                    square.position = CGPoint(x: posX, y: posY)
                    square.zPosition = 1003
                    inv[c][r] = square
                    addChild(square)
                }
            }
            for i in 0 ..< Player.inventory.count
            {
                let col = i % 5
                let row = 5 - (i / 5)
                let temp = inv[col][row]
                inv[col][row] = ItemNode(i: Player.inventory[i])
                inv[col][row].position = temp.position
                inv[col][row].zPosition = temp.zPosition
                temp.removeFromParent()
                addChild(inv[col][row])
            }
            
            self.setupLabels()
            self.updateLabels()
            
            for r in 0 ... 2
            {
                for c in 0 ... 4
                {
                    let square = SelectNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
                    let posX = 0 - (invBotLeft.x + marginWidth * CGFloat(c + 1) + size.width/2 + size.width * CGFloat(c))
                    let posY = 0 - (invBotLeft.y + marginHeight * CGFloat(r + 1) + size.height/2 + size.height * CGFloat(r))
                    square.position = CGPoint(x: posX, y: posY)
                    square.zPosition = 1003
                    mInv[c][r] = square
                    addChild(square)
                }
            }
            for i in 0 ..< Constants.merchantInventory.count
            {
                let col = 4 - (i % 5)
                let row = (i / 5)
                let temp = mInv[col][row]
                mInv[col][row] = ItemNode(i: Constants.merchantInventory[i])
                mInv[col][row].position = temp.position
                mInv[col][row].zPosition = temp.zPosition
                temp.removeFromParent()
                addChild(mInv[col][row])
            }
            vendorButton.position = CGPoint(x: merchantCenter.x, y: 0 - (invBotLeft.y + marginHeight * CGFloat(4) + size.height/2 + size.height * CGFloat(3)))
            vendorButton.back()
            addChild(vendorButton)
            
            addChild(centerLine)
            addChild(mainFrame)
            addChild(leftDividerLine)
            
            gameScene = scene
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            
            let selNode = atPoint(touches.first!.location(in: self))
            if selNode.isKind(of: ItemNode.self)
            {
                selectedNode = selNode as? ItemNode
                selectedSquare.position = selNode.position
                if selectedSquare.parent == nil
                {
                addChild(selectedSquare)
                }
                self.updateLabels()
                if selNode.position.x > 0 && (selNode as! ItemNode).item.isKind(of: Equipment.self)
                {
                    vendorButton.text.text = "Sell"
                    vendorButton.cost.text = "\(((selNode as! ItemNode).item as! Equipment).price)"
                    vendorButton.front()
                }
                else if selNode.position.x < 0 && (selNode as! ItemNode).item.isKind(of: Equipment.self)
                {
                    vendorButton.text.text = "Buy"
                    vendorButton.cost.text = "\(2 * ((selNode as! ItemNode).item as! Equipment).price)"
                    vendorButton.front()
                }
                else
                {
                    vendorButton.back()
                    vendorButton.text.text = "N/A"
                }
            }
            else if selNode.isKind(of: SellNode.self) || (selNode.parent?.isKind(of: SellNode.self))!
            {
                if selectedNode.position.x > 0
                {
                    let cubrixels = Item(t: "Cubrixel", q: (selectedNode.item as! Equipment).price, s: true)
                    Player.addDrop(cubrixels)
                    let i = Player.inventory.index(of: selectedNode.item as! Equipment)
                    Player.inventory.remove(at: i!)
                    selectedSquare.removeFromParent()
                    vendorButton.back()
                    self.updateLabels()
                }
                else
                {
                    var index = -1
                    for i in 0 ..< Player.inventory.count
                    {
                        if Player.inventory[i].type == "Cubrixel"
                        {
                            index = i
                        }
                    }
                    
                    let num = (selectedNode.item as! Equipment).price * 2
                    if(index < 0)
                    {
                        selectedSquare.removeFromParent()
                        labels[0].text = "You have no Cubrixels"
                        labels[1].text = ""
                        labels[2].text = ""
                        labels[3].text = ""
                        labels[4].text = ""
                        labels[5].text = ""
                        labels[6].text = ""
                    }
                    else if Player.inventory[index].quantity >= num
                    {
                        Player.addDrop(selectedNode.item as! Equipment)
                        Player.inventory[index].quantity -= num
                        
                        let mIndex = Constants.merchantInventory.index(of: selectedNode.item as! Equipment)
                        Constants.merchantInventory.remove(at: mIndex!)
                        selectedSquare.removeFromParent()
                        vendorButton.back()
                        self.updateLabels()
                    }
                    else
                    {
                        selectedSquare.removeFromParent()
                        labels[0].text = "Not Enough Cubrixels"
                        labels[1].text = ""
                        labels[2].text = ""
                        labels[3].text = ""
                        labels[4].text = ""
                        labels[5].text = ""
                        labels[6].text = ""

                    }
                }
                self.reloadTables()
                
            }
            else
            {
                selectedNode = nil
                if (selectedSquare.parent != nil)
                {
                    selectedSquare.removeFromParent()
                }
                vendorButton.back()
                self.updateLabels()
            }
    }
    func reloadTables()
    {
        for i in 0 ..< Player.inventory.count
        {
            let col = i % 5
            let row = 5 - (i / 5)
            let temp = inv[col][row]
            inv[col][row] = ItemNode(i: Player.inventory[i])
            inv[col][row].position = temp.position
            inv[col][row].zPosition = temp.zPosition
            temp.removeFromParent()
            addChild(inv[col][row])
        }
        
        for i in Player.inventory.count ..< 30
        {
            let col = i % 5
            let row = 5 - (i / 5)
            let temp = inv[col][row]
            inv[col][row] = SelectNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
            inv[col][row].position = temp.position
            inv[col][row].zPosition = temp.zPosition
            temp.removeFromParent()
            addChild(inv[col][row])

        }
        for i in 0 ..< Constants.merchantInventory.count
        {
            let col = 4 - (i % 5)
            let row = (i / 5)
            let temp = mInv[col][row]
            mInv[col][row] = ItemNode(i: Constants.merchantInventory[i])
            mInv[col][row].position = temp.position
            mInv[col][row].zPosition = temp.zPosition
            temp.removeFromParent()
            addChild(mInv[col][row])
        }
        for i in Constants.merchantInventory.count ..< 15
        {
            let col = 4 - (i % 5)
            let row = (i / 5)
            let temp = mInv[col][row]
            mInv[col][row] = SelectNode(texture: SKTexture(imageNamed: "noEquipment"), size: size)
            mInv[col][row].position = temp.position
            mInv[col][row].zPosition = temp.zPosition
            temp.removeFromParent()
            addChild(mInv[col][row])
        }
    }
    
        }


