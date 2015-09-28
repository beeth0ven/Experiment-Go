//
//  GetReviewsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetReviewsOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(reviewTo: CKExperiment) {
        self.init(type: .Refresh(reviewTo.reviewsQuery))
    }

}