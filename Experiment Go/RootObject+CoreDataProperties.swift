//
//  RootObject+CoreDataProperties.swift
//  Experiment Go
//
//  Created by luojie on 8/12/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension RootObject {

    @NSManaged var creationDate: NSDate?
    @NSManaged var creatorUserRecordID: String?
    @NSManaged var lastModifiedUserRecordID: String?
    @NSManaged var modificationDate: NSDate?
    @NSManaged var recordChangeTag: String?
    @NSManaged var recordID: String?

}
