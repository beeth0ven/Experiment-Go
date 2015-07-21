//
//  Root.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(Root)
class Root: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    
    
    struct Constants {
        static let DefaultSortKey = "createDate"
        static let CreateDateKey = "createDate"
    }
    
    override func awakeFromInsert() {
        createDate = NSDate()
        id = createDate?.timeIntervalSinceReferenceDate.description
    }

}
