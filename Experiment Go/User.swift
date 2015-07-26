//
//  User.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(User)
class User: Root {
    
    struct Constants {
        static let  UserNumber: Int = 1
        static let  EntityNameKey = "User"
        static let  NameKey = "name"
    }
    
    
    
    // Insert code here to add functionality to your managed object subclass
    class func currentUser() -> User! {
        let index = Constants.UserNumber % availableUserNames().count
        return userWithUserName(availableUserNames()[index])()!
    }
    
    class func userWithUserName(userName: String)() -> User! {
        var user: User!
        let context = NSManagedObjectContext.defaultContext()
        let request = NSFetchRequest(entityName: Constants.EntityNameKey)
        request.predicate = NSPredicate(format: "name == %@", userName)
        request.sortDescriptors = [NSSortDescriptor(key: Root.Constants.DefaultSortKey, ascending: false)]
        
        var matches: [AnyObject]
        do {
            try matches = context.executeFetchRequest(request)
        } catch {
            abort()
        }
        
        if matches.count == 0 {
            user = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: context) as! User
            user.name = userName
            
            // Save the context Once.
            NSManagedObjectContext.saveDefaultContext()
            
        } else if matches.count == 1 {
            user = matches.first! as? User
        } else {
            print("Error: Users has same name.")
            user = matches.first! as? User
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
