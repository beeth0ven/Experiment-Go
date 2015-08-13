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
class User: RootObject {
    
    struct Constants {
//        static let  UserNumber: Int = 1
        static let  EntityNameKey = "User"
        static let  NameKey = "name"
        static let  ProfileImageDataKey = "profileImageData"
    }
    
    var profileImage: UIImage? {
        get {
            return profileImageData == nil ? nil : UIImage(data: profileImageData!)
        }
        
        set {
            profileImageData = newValue == nil ? nil : UIImageJPEGRepresentation(newValue!, 1.0)
        }
    }
    
    // Insert code here to add functionality to your managed object subclass
    class func randomUser() -> User {
        let context = NSManagedObjectContext.defaultContext()
        let request = NSFetchRequest(entityName: Constants.EntityNameKey)
        request.sortDescriptors = [NSSortDescriptor(key: RootObject.Constants.DefaultSortKey, ascending: true)]
        
        var matches: [AnyObject]
        do {
            try matches = context.executeFetchRequest(request)
        } catch {
            abort()
        }
        
        let index = Int(arc4random_uniform(UInt32(matches.count)))
        return matches[index] as! User
    }
    
    class func currentUser() -> User! {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.currentUser
    }
    
    class func initAllUsers() -> [User] {
        var result = [User]()
        let path = NSBundle.mainBundle().pathForResource("User Info", ofType: "plist")!
        let dictionary = NSDictionary(contentsOfFile: path)!
        let userInfos = dictionary["Users"]! as! [Dictionary<String, AnyObject>]
        for userInfo in userInfos {
            let user = userWithUserInfo(userInfo)
            result.append(user)
        }
        return result

    }
    
    class func userWithUserInfo(userInfo: Dictionary<String, AnyObject>) -> User {
        let userName = userInfo["name"] as! String
        var user: User!
        let context = NSManagedObjectContext.defaultContext()
        let request = NSFetchRequest(entityName: Constants.EntityNameKey)
        request.predicate = NSPredicate(format: "name == %@", userName)
        request.sortDescriptors = [NSSortDescriptor(key: RootObject.Constants.DefaultSortKey, ascending: false)]
        
        
        var matches: [AnyObject]
        do {
            try matches = context.executeFetchRequest(request)
        } catch {
            abort()
        }
        
        if matches.count == 0 {
            user = RootObject.insertNewObjectForEntityForName(Constants.EntityNameKey) as! User
            user.name = userName
            let image = UIImage(named: userInfo["profileImageName"] as! String)!
            user.profileImageData = UIImageJPEGRepresentation(image, 1.0)
            
        } else if matches.count == 1 {
            user = matches.first! as? User
        } else {
            print("Error: Users has same name.")
            user = matches.first! as? User
        }
        
        return user
    }
    
    class func userWithUserName(userName: String)() -> User! {
        var user: User!
        let context = NSManagedObjectContext.defaultContext()
        let request = NSFetchRequest(entityName: Constants.EntityNameKey)
        request.predicate = NSPredicate(format: "name == %@", userName)
        request.sortDescriptors = [NSSortDescriptor(key: RootObject.Constants.DefaultSortKey, ascending: false)]
        
        var matches: [AnyObject]
        do {
            try matches = context.executeFetchRequest(request)
        } catch {
            abort()
        }
        
        if matches.count == 0 {
            user = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: context) as! User
            user.name = userName
            
            
        } else if matches.count == 1 {
            user = matches.first! as? User
        } else {
            print("Error: Users has same name.")
            user = matches.first! as? User
        }
        
        return user
    }
    

}
