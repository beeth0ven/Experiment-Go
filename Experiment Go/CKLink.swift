//
//  CKLink.swift
//  Experiment Go
//
//  Created by luojie on 9/22/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKLink: CKItem {
    
    convenience init(reviewTo experiment: CKExperiment) {
        let record = CKRecord(recordType: RecordType.Link.rawValue)
        self.init(record: record)
        self.creatorUser = CKUsers.currentUser
        self.type = .UserReviewToExperiment
        self.experiment = experiment
        self.experimentRef = CKReference(recordID: experiment.recordID, action: .DeleteSelf)
        self.toUserRef =
//            CKReference(record: experiment.creatorUser!.record, action: .DeleteSelf)
            CKReference(recordID: experiment.creatorUserRecordID!, action: .DeleteSelf)
        print(experiment.creatorUserRecordID!.recordName)
        
    }
    
    var type: LinkType? {
        get { return linkType == nil ? nil : LinkType(rawValue: linkType!) }
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

    override var displayTitle: String? {
        switch type! {
        case .UserReviewToExperiment:
            return "Review"
        default: return nil
        }
    }

    private var linkType: String? {
        get { return record[LinkKey.linkType.rawValue] as? String }
        set { record[LinkKey.linkType.rawValue] = newValue }
    }
    

}

enum LinkType: String {
    case UserReviewToExperiment
    case UserLikeExperiment
    case UserFollowUser
}

enum LinkKey: String {
    case linkType
    case content
    case experimentRef
    case toUserRef
}



