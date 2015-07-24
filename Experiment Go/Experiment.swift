//
//  Experiment.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(Experiment)
class Experiment: Root {
    
    struct Constants {
        static let  EntityNameKey = "Experiment"
        static let  TitleKey = "title"
        static let  BodyKey = "body"
        static let  AttributeKey = "Attribute"
        static let  ReviewsKey = "reviews"
        static let  UsersLikeMeKey = "usersLikeMe"
        static let  WhoPostKey = "whoPost"
        
    }
    
//    var reviewsAsArray: [Review]? {
//        let array = reviews?.allObjects as? [Review]
//        return array?.sort { $0.createDate! > $1.createDate! }
//    }
//    
//    var usersLikeMeAsArray: [User]? {
//        let array = reviews?.allObjects as? [User]
//        return array?.sort { $0.createDate! > $1.createDate! }
//    }
    
    // Insert code here to add functionality to your managed object subclass
    class func insertNewExperiment() -> Experiment! {
        let context = NSManagedObjectContext.defaultContext()
        let experiment = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: context) as! Experiment
        experiment.title = "Hallo"
        experiment.whoPost = User.currentUser()
        return experiment
    }
    
}
