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
class Review: Root {

// Insert code here to add functionality to your managed object subclass
    struct Constants {
        static let  EntityNameKey = "Review"
//        static let  TitleKey = "title"
//        static let  BodyKey = "body"
//        static let  PropertyKey = "Property"
//        static let  ReviewsKey = "reviews"
//        static let  UsersLikeMeKey = "usersLikeMe"
    }

    class func insertNewReviewInExperiment(experiment: Experiment) -> Review! {
        let context = NSManagedObjectContext.defaultContext()
        let review = NSEntityDescription.insertNewObjectForEntityForName(Constants.EntityNameKey, inManagedObjectContext: context) as! Review
        review.body = "How do you do!"
        review.experiment = experiment
        review.whoReview = User.defaultUser()
        return review
    }
}
