//
//  User+CoreDataProperties.swift
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

extension User {

    @NSManaged var displayName: String?
    @NSManaged var profileImageData: NSData?
    @NSManaged var profileImageURL: String?
    @NSManaged var followers: NSSet?
    @NSManaged var followingUsers: NSSet?
    @NSManaged var likedExperiments: NSSet?
    @NSManaged var postedExperiments: NSSet?
    @NSManaged var postedReviews: NSSet?

}
