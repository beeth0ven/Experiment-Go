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
        self.type = .UserReviewToExperiment
        self.experiment = experiment
        self.experimentRef = CKReference(recordID: experiment.recordID, action: .DeleteSelf)
        self.toUserRef = CKReference(recordID: experiment.creatorUserRecordID!, action: .DeleteSelf)
        self.creatorUser = CKUsers.CurrentUser
    }
    
    convenience init(followTo user: CKUsers) {
        let recordID = CKUsers.CurrentUser!.recordIDForFollowingUser(user)
        let record = CKRecord(recordType: RecordType.Link.rawValue, recordID: recordID)
        self.init(record: record)
        self.type = .UserFollowUser
        self.toUser = user
        self.toUserRef = CKReference(recordID: user.recordID, action: .DeleteSelf)
        self.creatorUser = CKUsers.CurrentUser
    }
    
    convenience init(like experiment: CKExperiment) {
        let recordID = CKUsers.CurrentUser!.recordIDForLikingExperiment(experiment)
        let record = CKRecord(recordType: RecordType.Link.rawValue, recordID: recordID)
        self.init(record: record)
        self.type = .UserLikeExperiment
        self.experiment = experiment
        self.experimentRef = CKReference(recordID: experiment.recordID, action: .DeleteSelf)
        self.toUserRef = CKReference(recordID: experiment.creatorUserRecordID!, action: .DeleteSelf)
        self.creatorUser = CKUsers.CurrentUser
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
    
    var toMe: Bool {
        guard let recordName = toUserRef?.recordID.recordName else { return false }
        let result = recordName == CKOwnerDefaultName || recordName == CKUsers.CurrentUser?.recordID.recordName
        if result == true  { toUser = CKUsers.CurrentUser }
        return result
    }
    
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



