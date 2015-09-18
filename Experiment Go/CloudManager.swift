//
//  CloudManager.swift
//  BabiFood
//
//  Created by luojie on 8/7/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

enum Notification: String {
    case CurrentUserHasChange
}

class CloudManager {
    // MARK: - Update Current User
    
    var publicCloudDatabase: CKDatabase { return CKContainer.defaultContainer().publicCloudDatabase }
    
    
    var currentUser: CKRecord? {
        get {
            guard let data = NSUbiquitousKeyValueStore.defaultStore().dataForKey(UbiquitousKey.CurrentUser) else { updateCurrentUser() ; return nil }
            return CKRecord.recordWithArchivedData(data)
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setData(newValue?.archivedData(), forKey: UbiquitousKey.CurrentUser)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
            currentUserDidSet()
        }
        
    }
    
    private func currentUserDidSet() {
        AppDelegate.Cache.Manager.cacheCurrentUser(currentUser)
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.CurrentUserHasChange.rawValue, object: nil)
    }
    
    
    func getCurrentUserProfileImageIfNeeded() {
        guard needGetCurrentUserProfileImage else { return }
        getCurrentUser(
            didGet: {
                (user) in
                let url = (user[UsersKey.ProfileImageAsset] as! CKAsset).fileURL
                UIImage.getImageForURL(url,
                    didGet: { (_) in
                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.CurrentUserHasChange.rawValue, object: nil)
                    }
                )
            },
            failed: nil
        )
    }
    
    private var needGetCurrentUserProfileImage: Bool {
        if let url = (currentUser?[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL {
            if AppDelegate.Cache.Manager.assetDataForURL(url) == nil { return true }
        }
        return false
    }
    
    func updateCurrentUser() {
        getCurrentUser(
            didGet: {
                (user) in
                self.currentUser = user
            },
            
            failed: nil
        )
    }
    
    private var isRequestingDiscoverability = false
    func getDiscoverabilityPermission(didGet didGet: (Bool) -> (), failed: ((NSError) -> ())?) {
        guard isRequestingDiscoverability == false else { return }
        isRequestingDiscoverability = true
        CKContainer.defaultContainer().requestApplicationPermission(.UserDiscoverability) { (applicationPermissionStatus, error) -> Void in
            self.isRequestingDiscoverability = false
            dispatch_async(dispatch_get_main_queue()) {
                guard  error == nil else { failed?(error!) ; return }
                didGet( applicationPermissionStatus == .Granted )
            }
        }
    }
    
    private var isFetchingCurrentUser = false
    func getCurrentUser(didGet didGet: (CKRecord) -> (), failed: ((NSError) -> ())?) {
        guard isFetchingCurrentUser == false else { return }
        isFetchingCurrentUser = true
        let fetchCurrentUserRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
        fetchCurrentUserRecordOperation.perRecordCompletionBlock = {
            (user, _, error) in
            self.isFetchingCurrentUser = false
            dispatch_async(dispatch_get_main_queue()) {
                guard  error == nil else { failed?(error!) ; return }
                didGet( user! )
            }
        }
        publicCloudDatabase.addOperation(fetchCurrentUserRecordOperation)
    }
    
    var hasCloudWritePermision: Bool? {
        get {
            return NSUbiquitousKeyValueStore.defaultStore().objectForKey(UbiquitousKey.HasCloudWritePermision) as? Bool
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setObject(newValue, forKey: UbiquitousKey.HasCloudWritePermision)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    private var displayNameInUsedError: NSError {
        let description = NSLocalizedString("This display name is in use.\n Please choose another one.", comment: "")
        return NSError(domain: "displayNameInUsedError", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    func setUserDisplayName(name: String, didSet: (() -> Void), failed: ((NSError) -> Void)?) {
        
        func checkDisplayNameAvaliable(avaliabled: () -> Void) {
            let displayNameRecord = CKRecord(recordType: RecordType.DisplayName.rawValue, recordID: CKRecordID(recordName: name.lowercaseString))
            publicCloudDatabase.saveRecord(displayNameRecord,
                didSave: { avaliabled() },
                failed: { $0.code == CKErrorCode.ServerRecordChanged.rawValue ? failed?(self.displayNameInUsedError) : failed?($0) }
            )
        }
        
        checkDisplayNameAvaliable {
            self.getCurrentUser(
                didGet: {
                    (currentUser) in
                    guard currentUser[UsersKey.DisplayName] == nil else {  self.currentUser = currentUser ; didSet() ; return }
                    currentUser[UsersKey.DisplayName] = name
                    self.publicCloudDatabase.saveRecord(currentUser, didSave: { self.currentUser = currentUser ; didSet()}, failed: failed)
                },
                failed: failed
            )
        }
        
    }
    
    // MARK: - Liked Experiments

    func amILikingThisExperiment(experiment: CKRecord) -> Bool {
        return likedExperiments.contains(experiment.recordID.recordName)
    }
    
    func likeExperiment(experiment: CKRecord, completionHandler: (NSError?) -> ()) {
        let fanLink = CKRecord(fanLinkToExperiment: experiment)
        publicCloudDatabase.saveRecord(fanLink) {
            (fanLink, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.likedExperiments = self.likedExperiments + [experiment.recordID.recordName]
        }
    }
    
    
    func unLikeExperiment(experiment: CKRecord, completionHandler: (NSError?) -> ()) {
        let fanLinkRecordID = CKRecordID(fanLinktoExperiment: experiment)
        AppDelegate.Cloud.Manager.publicCloudDatabase.deleteRecordWithID(fanLinkRecordID) {
            (_, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.likedExperiments = self.likedExperiments.filter { $0 != experiment.recordID.recordName }
        }
    }
    

    private var likedExperiments: [String] {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().arrayForKey(UbiquitousKey.LikedExperiments) as? [String] ?? [String]()
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setArray(newValue, forKey: UbiquitousKey.LikedExperiments)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    // MARK: - Following Users

    func amIFollowingTheUser(user: CKRecord) -> Bool {
        return followingUsers.contains(user.recordID.recordName)
    }
    
    func followUser(user: CKRecord, completionHandler: (NSError?) -> ()) {
        let followLink = CKRecord(followLinkToUser: user)
        
        publicCloudDatabase.saveRecord(followLink) {
            (followLink, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.followingUsers.append(user.recordID.recordName)
        }
        
    }
    
    func unfollowUser(user: CKRecord, completionHandler: (NSError?) -> ()) {
        let followLinkRecordID = CKRecordID(followLinktoUser: user)
        AppDelegate.Cloud.Manager.publicCloudDatabase.deleteRecordWithID(followLinkRecordID) {
            (_, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.followingUsers = self.followingUsers.filter { $0 != user.recordID.recordName }
        }
    }
    
    
    private var followingUsers: [String] {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().arrayForKey(UbiquitousKey.FollowingUsers) as? [String] ?? [String]()
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setArray(newValue, forKey: UbiquitousKey.FollowingUsers)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }

    // MARK: - Notified
    func hasSetupSubscription() -> Bool { return subscriptionID != nil }
    
    private var subscription: CKSubscription {
        
        let options: CKSubscriptionOptions = .FiresOnRecordCreation
        
        
        let predicate = NSPredicate.predicateForFollowLinkToUser(currentUser!)
        let subscription = CKSubscription(
            recordType: RecordType.Link.rawValue,
            predicate: predicate,
            options: options
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = "Some one is following you!"
        notificationInfo.desiredKeys = [LinkKey.LinkType, LinkKey.From, LinkKey.To]

        subscription.notificationInfo = notificationInfo

        return subscription
    }
    
    func doNotify(completionHandler: (NSError?) -> ()) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).requestForRemoteNotifications()

        guard subscriptionID == nil else { return }
        
        publicCloudDatabase.saveSubscription(subscription) {
            (subscription, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.subscriptionID = subscription?.subscriptionID
            print("subscriptionID: \(self.subscriptionID!)")
        }

    }
    
    func doUnNotify(completionHandler: (NSError?) -> ()) {
        guard subscriptionID != nil else { return }
        publicCloudDatabase.deleteSubscriptionWithID(subscriptionID!) {
            (_, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; print(error!.localizedDescription) ;return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.subscriptionID = nil
        }
    }
    
    private var subscriptionID: String? {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().stringForKey(UbiquitousKey.SubscriptionID)
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setObject(newValue, forKey: UbiquitousKey.SubscriptionID)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    
    
    // MARK: - Previous Change Token
    
    var previousChangeToken: CKServerChangeToken?  {
        get {
            guard let encodedObjectData = NSUbiquitousKeyValueStore.defaultStore().objectForKey(UbiquitousKey.PreviousChangeToken) as? NSData else { return nil }
            return CKServerChangeToken.tokenWithArchivedData(encodedObjectData)
        }
        
        set(newToken) {
            NSUbiquitousKeyValueStore.defaultStore().setObject(newToken?.archivedData(), forKey:UbiquitousKey.PreviousChangeToken)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
    }
    
    var notificationRecords: [[CKRecord]] {
        
        get {
            let datas =  NSUbiquitousKeyValueStore.defaultStore().arrayForKey(UbiquitousKey.NotificationRecords) as? [[NSData]] ?? [[NSData]]()
            return datas.map { $0.map { CKRecord.recordWithArchivedData($0) } }
        }
        
        set {
            let datas = newValue.map { $0.map { $0.archivedData() } }
            NSUbiquitousKeyValueStore.defaultStore().setArray(datas, forKey: UbiquitousKey.NotificationRecords)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    var experimentSearchHistories: [String] {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().arrayForKey(UbiquitousKey.ExperimentSearchHistories) as? [String] ?? [String]()
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setArray(newValue, forKey: UbiquitousKey.ExperimentSearchHistories)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }

    }
    
    func resetiCloudKVS() {
        likedExperiments = []
        followingUsers = []
        notificationRecords = []
        
    }
    
    
    
    
    // MARK: - KVO
    
    init() { startObserve() }
    deinit { stopObserve()  }
    
    var kvso:  NSObjectProtocol?
    
    func startObserve() {
        kvso =
            NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
                object: NSUbiquitousKeyValueStore.defaultStore(),
                queue: NSOperationQueue.mainQueue()) { (noti) in
                    guard let changedKeys = (noti.userInfo as! Dictionary<String,AnyObject>)[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
                    guard changedKeys.contains(UbiquitousKey.CurrentUser) else { return }
                    self.currentUserDidSet()
                    
        }
        
    }
    
    func stopObserve() {
        if kvso != nil { NSNotificationCenter.defaultCenter().removeObserver(kvso!) }
    }
    
    private struct UbiquitousKey {
        static let CurrentUser = "CloudManager.currentUser"
        static let LikedExperiments = "CloudManager.likedExperiments"
        static let FollowingUsers = "CloudManager.followingUsers"
        static let SubscriptionID = "CloudManager.subscriptionID"
        static let NotificationRecords = "CloudManager.notificationRecords"
        static let PreviousChangeToken = "CloudManager.previousChangeToken"
        static let ExperimentSearchHistories = "CloudManager.experimentSearchHistories"
        static let HasCloudWritePermision = "CloudManager.hasCloudWritePermision"
     
    }
    
}

extension NSURL {
    class func profileImageURLForUser(user: CKRecord) -> NSURL? {
        guard let type = RecordType(rawValue: user.recordType) else { return nil }
        guard case .Users = type else { return nil }
        return (user[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
}

extension NSPredicate {
    class func predicateForFollowLinkFromUser(user: CKRecord) -> NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserFollowUser.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user.recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])

    }
    
    class func predicateForFollowLinkToUser(user: CKRecord) -> NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserFollowUser.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", LinkKey.To, user.recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
        
    }
    
    class func predicateForLikeLinkFromUser(user: CKRecord) -> NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserLikeExperiment.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user.recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
    }
    
    class func predicateForExperimentsPostedBy(user: CKRecord) -> NSPredicate {
        return NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user.recordID)
    }
    
    class func predicateForFanLinkToExperiment(experiment: CKRecord) -> NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserLikeExperiment.rawValue)
        let toPredicate = NSPredicate(format: "%K = %@", LinkKey.To, experiment)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [toPredicate, typePredicate])
    }
    
    class func predicateForReviewToExperiment(experiment: CKRecord) -> NSPredicate {
       return NSPredicate(format: "%K = %@", ReviewKey.To, experiment)
    }

}

