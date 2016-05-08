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
    
    init(t: String)
    {
        super.init()
        self.type = t
    }
    convenience init(t: String, q: Int)
    {
        self.init(t: t)
        quantity = q
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
        return dic
    }
    
    convenience init(dic: [String: AnyObject])
    {
        self.init(t: (dic["type"] as? String)!, q: (dic["quantity"] as? Int)!)
    }
}
