//
//  GetFollowersOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/29/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetFollowersOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(followersFrom user: CKUsers) {
        self.init(type: .Refresh(user.followersQuery))
    }
    
    private var currentPageLinks: [CKLink] { return (currentPageItems as? [CKLink]) ?? [CKLink]() }
    override var currentPageCallBackItems: [CKItem] { return currentPageLinks.flatMap { $0.creatorUser } }
    
}