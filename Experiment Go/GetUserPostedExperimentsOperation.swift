//
//  GetUserPostedExperimentsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetUserPostedExperimentsOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(postedBy: CKUsers) {
        self.init(type: .Refresh(postedBy.postedExperimentsQuery))
    }

}