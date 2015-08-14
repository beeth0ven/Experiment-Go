//
//  ArrayTransformer.swift
//  Experiment Go
//
//  Created by luojie on 8/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ArrayTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.classForCoder()
    }

    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return value == nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(value!)
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        return value == nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(value as! NSData)
    }
    

}
