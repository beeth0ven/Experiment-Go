//
//  CKLinks.swift
//  Experiment Go
//
//  Created by luojie on 9/22/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKLinks: CKItem {
    
    var type: Type? {
        get { return linkType == nil ? nil : Type(rawValue: linkType!) }
        set { linkType = newValue?.rawValue }
    }
    
    var content: String? {
        get { return record[LinkKey.content.rawValue] as? String }
        set { record[LinkKey.content.rawValue] = newValue }
    }
    
    var experimentRef: CKReference? {
        get { return record[LinkKey.experimentRef.rawValue] as? CKReference }
        set { record[LinkKey.experimentRef.rawValue] = newValue }
    }
    
    var toUserRef: CKReference? {
        get { return record[LinkKey.toUserRef.rawValue] as? CKReference }
        set { record[LinkKey.toUserRef.rawValue] = newValue }
    }
    
    var experiment: CKExperiment?
    var toUser: CKUsers?

    
    private var linkType: String? {
        get { return record[LinkKey.linkType.rawValue] as? String }
        set { record[LinkKey.linkType.rawValue] = newValue }
    }
    
    enum Type: String {
        case UserReviewToExperiment
        case UserLikeExperiment
        case UserFollowUser
        case UserDisplayName
    }
}

enum LinkKey: String {
    case linkType
    case content
    case experimentRef
    case toUserRef
}



