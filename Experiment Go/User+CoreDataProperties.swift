//
//  User+CoreDataProperties.swift
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

extension User {

    @NSManaged var name: String?
    @NSManaged var email: String?
    @NSManaged var password: String?
    @NSManaged var profileImageData: NSData?
    @NSManaged var postedReviews: NSSet?
    @NSManaged var postedExperiments: NSSet?
    @NSManaged var likedExperiments: Experiment?
    @NSManaged var followingUsers: NSSet?
    @NSManaged var followers: NSSet?

}