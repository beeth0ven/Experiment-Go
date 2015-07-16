//
//  User.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
class User: Root {
    
    struct Constants {
        static let  EntityNameKey = "User"
    }
    
    
    
    // Insert code here to add functionality to your managed object subclass
    class func defaultUserInManagedObjectContext(managedObjectContext: NSManagedObjectContext) -> User? {
        var user: User?
        user = userWithUserName(availableUserNames().first!, inManagedObjectContext: managedObjectContext)()
        return user
    }
    
    class func userWithUserName(userName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext)() -> User? {
        var user: User?
        let request = NSFetchRequest(entityName: Constants.EntityNameKey)
        request.predicate = NSPredicate(format: "name == %@", userName)
        request.sortDescriptors = [NSSortDescriptor(key: Root.Constants.DefaultSortKey, ascending: false)]
        
        var matches: [AnyObject]
        do {
            try matches = managedObjectContext.executeFetchRequest(request)
        } catch {
            abort()
        }
        
        if matches.count == 0 {
            user = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: managedObjectContext) as? User
            user?.name = userName
            
            // Save the context Once.
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                abort()
            }
            
            
        } else if matches.count == 1 {
            user = matches.first! as? User
        } else {
            print("Error: Users has same name.")
        }
        
        return user
    }
    
    class func availableUserNames() -> [String] {
        return [
            "Luo Jie",
            "iPhone",
            "iPad Mini",
            "iPad Air",
            "Mac Air"
        ]
    }
}
