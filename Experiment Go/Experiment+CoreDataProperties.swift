//
//  Experiment+CoreDataProperties.swift
//  Experiment Go
//
//  Created by luojie on 8/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Experiment {

    @NSManaged var body: String?
    @NSManaged var imageData: NSData?
    @NSManaged var reviewIDs: NSArray?
    @NSManaged var title: String?
    @NSManaged var reviews: NSSet?
    @NSManaged var usersLikeMe: NSSet?
    @NSManaged var whoPost: User?

}
