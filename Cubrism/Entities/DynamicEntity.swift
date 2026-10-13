//
//  CharacterEntity.swift
//  Cubrism
//
//  Created by Brendan Sanderson on 3/13/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import SpriteKit
import GameplayKit

class DynamicEntity: GKEntity {
    var alive = true
    func act(_ currentTime: TimeInterval)
    {
        
    }

    func retire() {
        alive = false
        for component in components { removeComponent(ofType: type(of: component)) }
    }

}
