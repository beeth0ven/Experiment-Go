//
//  CloudKit-Extension.swift
//  Experiment Go
//
//  Created by luojie on 9/8/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

extension CKSubscription {
    
    convenience init(likeToExperiment experiment: CKRecord) {
        let fansSubscriptionID = "\(experiment.recordID.recordName)-fans-subscription"
        self.init(
            recordType: RecordType.Link.rawValue,
            predicate: NSPredicate.predicateForFanLinkToExperiment(experiment),
            subscriptionID: fansSubscriptionID,
            options: .FiresOnRecordCreation
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = "New fan to your experiment!"
        notificationInfo.desiredKeys = [LinkKey.LinkType, LinkKey.From, LinkKey.To]
        
        self.notificationInfo = notificationInfo
    }
    
    convenience init(reviewToExperiment experiment: CKRecord) {
        let reviewsSubscriptionID = "\(experiment.recordID.recordName)-reviews-subscription"
        self.init(
            recordType: RecordType.Review.rawValue,
            predicate: NSPredicate.predicateForReviewToExperiment(experiment),
            subscriptionID: reviewsSubscriptionID,
            options: .FiresOnRecordCreation
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = "New review to your experiment!"
        notificationInfo.desiredKeys = [ReviewKey.From, ReviewKey.To]
        
        self.notificationInfo = notificationInfo
    }
}


extension CKRecordID {
    convenience init(fanLinktoExperiment experiment: CKRecord) {
        let currentUser = AppDelegate.Cloud.Manager.currentUser!
        let userRecordName = String(currentUser.recordID.recordName.characters.dropFirst())
        let name = "\(userRecordName)-\(LinkType.UserLikeExperiment.rawValue)-\(experiment.recordID.recordName)"
        self.init(recordName: name)
        print(name)
    }
    
    convenience init(followLinktoUser user: CKRecord) {
        let currentUser = AppDelegate.Cloud.Manager.currentUser!
        let currentUserRecordName = String(currentUser.recordID.recordName.characters.dropFirst())
        let userRecordName = String(user.recordID.recordName.characters.dropFirst())
        let name = "\(currentUserRecordName)-\(LinkType.UserFollowUser.rawValue)-\(userRecordName)"
        self.init(recordName: name)
        print(name)
        
    }
}

extension CKRecord {
    convenience init(fanLinkToExperiment experiment: CKRecord) {
        let recordID = CKRecordID(fanLinktoExperiment: experiment)
        let currentUser = AppDelegate.Cloud.Manager.currentUser!
        self.init(linkType: LinkType.UserLikeExperiment, recordID: recordID)
        self[LinkKey.From] = CKReference(recordID: currentUser.recordID, action: .DeleteSelf)
        self[LinkKey.To] = CKReference(record: experiment, action: .DeleteSelf)
        self[RecordKey.AboutMe] = "\(currentUser[UsersKey.DisplayName] as! String) liked experiment <\(experiment[ExperimentKey.Title] as! String)> !"
    }
    
    convenience init(followLinkToUser user: CKRecord) {
        let recordID = CKRecordID(followLinktoUser: user)
        let currentUser = AppDelegate.Cloud.Manager.currentUser!
        self.init(linkType: LinkType.UserFollowUser, recordID: recordID)
        self[LinkKey.From] = CKReference(recordID: currentUser.recordID, action: .DeleteSelf)
        self[LinkKey.To] = CKReference(record: user, action: .DeleteSelf)
        self[RecordKey.AboutMe] = "\(user[UsersKey.DisplayName] as! String) is following you!"
    }
    
    convenience init(reviewToExperiment experiment: CKRecord) {
        self.init(recordType: RecordType.Review.rawValue)
        let user = AppDelegate.Cloud.Manager.currentUser!
        self[ReviewKey.From] = CKReference(recordID: user.recordID, action: .DeleteSelf)
        self[ReviewKey.To] = CKReference(record: experiment, action: .DeleteSelf)
        self[RecordKey.AboutMe] = "\(user[UsersKey.DisplayName] as! String) has reviewed to experiment <\(experiment[ExperimentKey.Title] as! String)> !"
    }
    
    convenience init(linkType: LinkType, recordID: CKRecordID) {
        self.init(recordType: LinkKey.RecordType, recordID: recordID)
        self[LinkKey.LinkType] = linkType.rawValue
    }
    

    
}


extension CKRecord {
    class func recordWithArchivedData(data: NSData) -> CKRecord
    {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! CKRecord
    }
    
    func archivedData() -> NSData
    {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    var smartStringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.smartStringFormDate(date)
    }
    
    var stringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
    }
    
    
    var linkToRecordID: CKRecordID? {
        guard recordType == LinkKey.RecordType else { return nil }
        guard let ref = self[LinkKey.To] as? CKReference else { return nil }
        return ref.recordID
    }
    
    var subscriptionsToAdd: [CKSubscription]? {
        let type = RecordType(rawValue: recordType)!
        switch type {
        case .Experiment:
            let experiment = self
            let fansSubscription = CKSubscription(likeToExperiment: experiment)
            let reviewsSubscription = CKSubscription(reviewToExperiment: experiment)
            return [fansSubscription, reviewsSubscription]
            
        default: return nil
        }
    }
    
    var subscriptionIDsToDelete: [String]? { return subscriptionsToAdd?.map { $0.subscriptionID } }

}


extension CKServerChangeToken{
    class func tokenWithArchivedData(data: NSData) -> CKServerChangeToken
    {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! CKServerChangeToken
    }
    
    func archivedData() -> NSData
    {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
}

// MARK: - Cloud Kit Record Key




struct ReviewKey {
    static let RecordType = "Review"
    static let Body = "body"
    static let To = "to"
    static let From = "from"
}

struct LinkKey {
    static let RecordType = "Link"
    static let LinkType = "linkType"
    static let From = "from"
    static let To = "to"
}


enum LinkType: String {
    case UserLikeExperiment
    case UserFollowUser
}




