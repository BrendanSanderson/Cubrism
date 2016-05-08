//
//  ProgressBar.swift
//  Cubrism
//
//  Created by Henry Sanderson on 3/12/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit

class ProgressBar: SKCropNode {
    var sprite = SKSpriteNode()
    override init () {
        super.init()
        
        self.maskNode = SKSpriteNode(color: UIColor.redColor(), size: CGSizeMake(300,10))
        
       // sprite = SKSpriteNode(color: UIColor.whiteColor(), size: CGSizeMake(300,10))
        //setProgress(0.3)
        //self.addChild(sprite)
    }
    init (color: UIColor) {
        super.init()
        self.maskNode = SKSpriteNode(color:color, size: CGSizeMake(150,10))
        sprite = SKSpriteNode(color: UIColor.whiteColor(), size: CGSizeMake(150,10))
        setProgress(0.3)
        self.addChild(sprite)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProgress (progress: CGFloat) {
    self.maskNode!.xScale = progress
    }

}
