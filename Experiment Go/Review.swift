//
//  Review.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(Review)
class Review: RootObect {

// Insert code here to add functionality to your managed object subclass
    struct Constants {
        static let  EntityNameKey = "Review"
        static let  WhoReviewKey = "whoReview"
//        static let  BodyKey = "body"
//        static let  PropertyKey = "Property"
//        static let  ReviewsKey = "reviews"
//        static let  UsersLikeMeKey = "usersLikeMe"
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        body = "How do you do!"
        whoReview = User.currentUser()
    }
    
}
