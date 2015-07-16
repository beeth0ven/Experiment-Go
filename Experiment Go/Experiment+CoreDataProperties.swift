//
//  Experiment+CoreDataProperties.swift
//  Experiment Go
//
//  Created by luojie on 7/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Experiment {

    @NSManaged var title: String?
    @NSManaged var body: String?
    @NSManaged var reviews: NSSet?
    @NSManaged var whoPost: User?
    @NSManaged var usersLikeMe: NSSet?

}
