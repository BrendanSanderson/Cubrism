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
        self.type = aDecoder.decodeObjectForKey("type") as! String
        self.quantity = aDecoder.decodeObjectForKey("quantity") as! Int
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(type, forKey: "type")
        aCoder.encodeObject(quantity, forKey: "quantity")
        
    }
    func toDictionary() -> [String:AnyObject]
    {
        var dic = [String : AnyObject]()
        dic["type"] = type
        dic["quantity"] = quantity
        dic["stackable"] = stackable
        return dic
    }
    
    convenience init(dic: [String: AnyObject])
    {
        self.init(t: (dic["type"] as? String)!, q: (dic["quantity"] as? Int)!, s: (dic["quantity"] as? Bool)!)
    }
}
