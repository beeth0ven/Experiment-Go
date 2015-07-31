//
//  RootObject+CoreDataProperties.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension RootObject {

    @NSManaged var createDate: NSDate?
    @NSManaged var id: String?
    @NSManaged var modifyDate: NSDate?

}
