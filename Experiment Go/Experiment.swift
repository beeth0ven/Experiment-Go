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
class Experiment: RootObject {
    
    struct Constants {
        static let  EntityNameKey = "Experiment"
        static let  TitleKey = "title"
        static let  BodyKey = "body"
        static let  AttributeKey = "Attribute"
        static let  ReviewsKey = "reviews"
        static let  UsersLikeMeKey = "usersLikeMe"
        static let  WhoPostKey = "whoPost"
        
    }

    // Insert code here to add functionality to your managed object subclass
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        title = "Hallo"
        body = "I'm here guy."
        whoPost = User.currentUser()
    }
    
    var image: UIImage? {
        get {
            guard imageData != nil else { return nil }
            return UIImage(data: imageData!)
        }
        
        set {
            guard newValue != nil else { return imageData = nil }
            imageData = UIImageJPEGRepresentation(newValue!, 1.0)
        }
    }
    
}
