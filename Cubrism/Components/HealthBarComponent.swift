//
//  HealthBarComponent.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/12/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import GameplayKit
import SpriteKit


// Reveal a fixed-size texture rather than squeezing its borders and end caps.
func addBarFill(_ sprite: SKSpriteNode, to parent: SKNode) {
    let crop = SKCropNode()
    crop.zPosition = 1
    let mask = SKSpriteNode(color: .white, size: sprite.size)
    mask.anchorPoint = .zero
    sprite.anchorPoint = .zero
    crop.maskNode = mask
    crop.addChild(sprite)
    parent.addChild(crop)
}

func updateBarFill(_ sprite: SKSpriteNode, value: Double, maximum: Double) {
    guard let crop = sprite.parent as? SKCropNode,
          let mask = crop.maskNode as? SKSpriteNode else { return }
    let fraction = maximum > 0 ? min(1, max(0, value / maximum)) : 0
    mask.size.width = sprite.size.width * CGFloat(fraction)
    crop.isHidden = fraction == 0
}

class HealthBarComponent: GKComponent {
    var scene: GameScene!
    var coordinate: CGPoint!
    var playerSprite: SKSpriteNode!
    var healthBar = SKCropNode()
    let healthNode = SKNode()
    let shieldNode = SKNode()
    var shieldCropSprite = SKSpriteNode()
    var healthCropSprite = SKSpriteNode()
    init(scene: GameScene, playerNode: SKNode, sprite:SKSpriteNode) {
        let totalHeight = scene.size.height * 0.064
        let healthBackgroundSprite = SKSpriteNode(texture: GameArt.texture( "healthBarBottom"), size: CGSize(width: CGFloat(scene.size.width * 0.25), height: totalHeight))
        healthCropSprite = SKSpriteNode(texture: GameArt.texture( "healthBarTop"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight ))
        healthCropSprite.zPosition = (healthBackgroundSprite.zPosition + 1)
        healthNode.addChild(healthBackgroundSprite)
        addBarFill(healthCropSprite, to: healthNode)
        healthNode.position = CGPoint(x: scene.size.width * 0.05 + 22, y: scene.size.height - totalHeight - 8)
        healthBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        healthCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(healthNode)
        self.scene = scene
        shieldCropSprite = SKSpriteNode(texture: GameArt.texture( "shieldBarTop"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight))
        let shieldBackgroundSprite = SKSpriteNode(texture: GameArt.texture( "shieldBarBottom"), size: CGSize(width: CGFloat(scene.size.width * 0.25),height: totalHeight))
        shieldNode.addChild(shieldBackgroundSprite)
        addBarFill(shieldCropSprite, to: shieldNode)
        shieldCropSprite.zPosition = (shieldBackgroundSprite.zPosition + 1)
        shieldNode.position = CGPoint(x: scene.size.width * 0.05 + 22, y: scene.size.height - totalHeight - 8)
        shieldBackgroundSprite.anchorPoint = CGPoint(x:0,y:0)
        shieldCropSprite.anchorPoint = CGPoint(x:0,y:0)
        scene.addChild(shieldNode)
        
        let outline = SKShapeNode(rect: CGRect(x:0,y:0,width:healthCropSprite.size.width,height:totalHeight), cornerRadius:totalHeight/2)
        outline.fillColor = .clear
        outline.strokeColor = GameArt.gold
        outline.lineWidth = 0.8
        outline.zPosition = 3
        healthNode.addChild(outline)

        // Icons sit outside the clipped fills so they remain visible when empty.
        let iconX: CGFloat = -12
        let iconBackground = SKShapeNode(rect: CGRect(x: iconX - 10, y: 0,
                                                     width: 20, height: totalHeight),
                                         cornerRadius: 3)
        iconBackground.fillColor = GameArt.ink
        iconBackground.strokeColor = GameArt.gold
        iconBackground.zPosition = 3
        healthNode.addChild(iconBackground)
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        for (symbol, title, node, y) in [("heart.fill", "Health", healthNode, totalHeight * 0.75),
                                         ("shield.fill", "Shield", shieldNode, totalHeight * 0.25)] {
            let image = UIImage(systemName: symbol, withConfiguration: configuration)!
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            // Bake the symbol tint into pixels; SpriteKit ignores UIImage template tint.
            let renderedImage = UIGraphicsImageRenderer(size: image.size).image { _ in
                image.draw(at: .zero)
            }
            let icon = SKSpriteNode(texture: SKTexture(image: renderedImage))
            icon.size = CGSize(width: 11 * image.size.width / image.size.height, height: 11)
            icon.position = CGPoint(x: iconX, y: y)
            icon.zPosition = 4
            icon.isAccessibilityElement = true
            icon.accessibilityLabel = title
            node.addChild(icon)
        }

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateBars(_ shield: Double, health: Double)
    {
        updateBarFill(shieldCropSprite, value: shield, maximum: Player.shield)
        updateBarFill(healthCropSprite, value: health, maximum: Player.health)
    }
    
}
