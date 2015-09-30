//
//  GetCurrentUserInteretedExperimentsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetCurrentUserInteretedExperimentsOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init() {
        self.init(type: .Refresh(CKUsers.CurrentUserInteretedExperimentsQuery))
    }
    
}