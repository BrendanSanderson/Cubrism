//
//  Item.swift
//  Cubrism
//
//  Created by Henry Sanderson on 4/30/16.
//  Copyright © 2016 Brendan. All rights reserved.
//

import UIKit
import SpriteKit

class Item: NSObject {
    var type: String!
    var quantity = 1
    var stackable = false
    
    init(t: String)
    {
        super.init()
        self.type = t
        if t == "Coin"
        {
            self.type = "Cubrixel"
        }
    }
    convenience init(t: String, q: Int, s: Bool)
    {
        self.init(t: t)
        quantity = q
        stackable = s
        
    }
    
    
    init(coder aDecoder: NSCoder!) {
        self.type = aDecoder.decodeObject(forKey: "type") as! String
        self.quantity = aDecoder.decodeObject(forKey: "quantity") as! Int
        
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        aCoder.encode(type, forKey: "type")
        aCoder.encode(quantity, forKey: "quantity")
        
    }
    func toDictionary() -> [String:AnyObject]
    {
        var dic = [String : AnyObject]()
        dic["type"] = type as AnyObject
        dic["quantity"] = quantity as AnyObject
        dic["stackable"] = stackable as AnyObject
        return dic
    }
    
    convenience init(dic: [String: AnyObject])
    {
        self.init(t: (dic["type"] as? String)!, q: (dic["quantity"] as? Int)!, s: (dic["stackable"] as? Bool)!
        )
    }
}
