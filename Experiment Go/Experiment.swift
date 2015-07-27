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
class Experiment: RootObect {
    
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
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        title = "Hallo"
        whoPost = User.currentUser()
    }
    
}
