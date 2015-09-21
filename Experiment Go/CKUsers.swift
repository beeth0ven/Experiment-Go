//
//  CKUsers.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKUsers: CKObject {
    
    var displayName: String? {
        get { return record[UsersKey.DisplayName] as? String }
        set { record[UsersKey.DisplayName] = newValue }
    }
    
    var profileImageAsset: CKAsset? {
        get { return record[UsersKey.ProfileImageAsset] as? CKAsset }
        set { record[UsersKey.ProfileImageAsset] = newValue }
    }
    
}

struct UsersKey {
    static let RecordType = "User"
    static let ProfileImageAsset = "profileImageAsset"
    static let DisplayName = "displayName"
    
}