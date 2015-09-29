//
//  CKUsers.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

enum Notification: String {
    case currentUserHasChange
}

class CKUsers: CKItem {
    
    var profileImageAsset: CKAsset? {
        get { return record[UsersKey.profileImageAsset.rawValue] as? CKAsset }
        set { record[UsersKey.profileImageAsset.rawValue] = newValue }
    }
    
    var displayName: String? {
        get { return record[UsersKey.displayName.rawValue] as? String }
        set { record[UsersKey.displayName.rawValue] = newValue }
    }
    
    var aboutMe: String? {
        get { return record[UsersKey.aboutMe.rawValue] as? String }
        set { record[UsersKey.aboutMe.rawValue] = newValue }
    }
    
    var isMe: Bool  { return recordID.recordName == CKOwnerDefaultName || recordID.recordName == CKUsers.CurrentUser?.recordID.recordName }
    
    override var displayTitle: String? { return displayName }

    // MARK: - Current User

    static var CurrentUser: CKUsers? = CurrentUserFromiCloudKVS
    
    static func saveCurrentUser() {
        iCloudKeyValueStore.setData(CurrentUser?.archivedData(), forKey: Key.CurrentUser.rawValue)
        iCloudKeyValueStore.synchronize()
    }
    
    static func UpdateCurrentUserFromiCloudKVS() {
        guard let user = CurrentUserFromiCloudKVS else { CurrentUser = nil ; return }
        CurrentUser?.record = user.record
        PostCurrentUserHasChangeNotification()
    }
    
    static func UpdateCurrentUser() {
        GetCurrentUser(
            didGet: {
                if let currentUser = self.CurrentUser {
                    currentUser.record = $0.record
                } else {
                    self.CurrentUser = $0
                }
                saveCurrentUser()
                PostCurrentUserHasChangeNotification()
            }
        )
    }
    
    static func UpdateCurrentUserIfNeeded() {
        guard NeedUpdateCurrentUser else { return }
        UpdateCurrentUser()
    }
    
    static private var NeedUpdateCurrentUser: Bool {
        if let url = CurrentUser?.profileImageAsset?.fileURL {
            if AppDelegate.Cache.Manager.assetDataForURL(url) == nil { return true }
        }
        return false
    }
    
    
    private static var CurrentUserFromiCloudKVS: CKUsers? {
        guard let data = iCloudKeyValueStore.dataForKey(Key.CurrentUser.rawValue) else { return nil }
        return CKUsers(data: data)
    }
    
    static func PostCurrentUserHasChangeNotification() {
        notificationCenter.postNotificationName(Notification.currentUserHasChange.rawValue, object: nil)
    }
    
    static func GetCurrentUser(didGet didGet: (CKUsers) -> (), didFail: ((NSError) -> ())? = nil) {
        guard FetchingCurrentUser == false else { return }
        FetchingCurrentUser = true
        
        let fetchCurrentUserRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
        fetchCurrentUserRecordOperation.perRecordCompletionBlock = {
            (userRecord, _, error) in
            self.FetchingCurrentUser = false
            dispatch_async(dispatch_get_main_queue()) {
                guard  error == nil else { didFail?(error!) ; return }
                didGet( CKUsers(record: userRecord!) )
            }
        }
        publicCloudDatabase.addOperation(fetchCurrentUserRecordOperation)
    }
    private static var FetchingCurrentUser = false


    private static var iCloudKeyValueStore = NSUbiquitousKeyValueStore.defaultStore()
    private static var notificationCenter = NSNotificationCenter.defaultCenter()
    
    
    // MARK: - Liked Experiments
    
    static func AmILikingThisExperiment(experiment: CKExperiment) -> Bool {
        return LikedExperiments.contains(experiment.recordID.recordName)
    }
    
    static func LikeExperiment(experiment: CKExperiment, didLike: (Void -> Void)? = nil, didFail: ((NSError) -> Void)? = nil) {
        guard LikeOperationInProgress == false else { didFail?(NSError(description: ServerBusyDescription)) ; return }
        LikeOperationInProgress = true
        
        let fanLink = CKLink(like: experiment)
        fanLink.saveInBackground(
            didSave: {
                LikeOperationInProgress = false
                LikedExperiments.append(experiment.recordID.recordName)
                didLike?()
            },
            didFail: {
                LikeOperationInProgress = false
                didFail?($0)
            }
        )
    }
    
    
    static func UnlikeExperiment(experiment: CKExperiment, didUnlike: (Void -> Void)? = nil, didFail: ((NSError) -> Void)? = nil) {
        guard LikeOperationInProgress == false else { didFail?(NSError(description: ServerBusyDescription)) ; return }
        LikeOperationInProgress = true
        
        let fanLink = CKLink(like: experiment)
        fanLink.deleteInBackground(
            didDelete: {
                LikeOperationInProgress = false
                LikedExperiments = LikedExperiments.filter { $0 != experiment.recordID.recordName }
                didUnlike?()
            },
            didFail: {
                LikeOperationInProgress = false
                didFail?($0)
            }
        )
    }
    
    private static var LikeOperationInProgress = false

    private static var LikedExperiments: [String] {
        get { return iCloudKeyValueStore.arrayForKey(Key.LikedExperiments.rawValue) as? [String] ?? [String]() }
        set { iCloudKeyValueStore.setArray(newValue, forKey:Key.LikedExperiments.rawValue) }
        
    }

    func recordIDForLikingExperiment(experiment: CKExperiment) -> CKRecordID {
        let userRecordName = String(recordID.recordName.characters.dropFirst())
        let name = "\(userRecordName)-\(LinkType.UserLikeExperiment.rawValue)-\(experiment.recordID.recordName)"
        return CKRecordID.init(recordName: name)
    }
    
    // MARK: - Following Users
    
    static func AmIFollowingTo(user: CKUsers) -> Bool {
        return FollowingUsers.contains(user.recordID.recordName)
    }
    
    static func FollowUser(user: CKUsers, didFollow: (Void -> Void)? = nil, didFail: ((NSError) -> Void)? = nil) {
        guard FollowOperationInProgress == false else { didFail?(NSError(description: ServerBusyDescription)) ; return }
        FollowOperationInProgress = true
        
        let followLink = CKLink(followTo: user)
        followLink.saveInBackground(
            didSave: {
                FollowOperationInProgress = false
                FollowingUsers.append(user.recordID.recordName)
                didFollow?()
            },
            didFail: {
                FollowOperationInProgress = false
                didFail?($0)
            }
        )
    }
    
    static func UnfollowUser(user: CKUsers, didUnfollow: (Void -> Void)? = nil, didFail: ((NSError) -> Void)? = nil) {
        guard FollowOperationInProgress == false else { didFail?(NSError(description: ServerBusyDescription)) ; return }
        FollowOperationInProgress = true
        
        let followLink = CKLink(followTo: user)
        followLink.deleteInBackground(
            didDelete:  {
                FollowOperationInProgress = false
                FollowingUsers = FollowingUsers.filter { $0 != user.recordID.recordName }
                didUnfollow?()
            },
            didFail: {
                FollowOperationInProgress = false
                didFail?($0)
            }
        )
    }
    private static var FollowOperationInProgress = false
    private static let ServerBusyDescription = NSLocalizedString("Server is busy, Please retry later.", comment: "")

    
    
    private static var FollowingUsers: [String] {
        get { return iCloudKeyValueStore.arrayForKey(Key.FollowingUsers.rawValue) as? [String] ?? [String]() }
        set { iCloudKeyValueStore.setArray(newValue, forKey:Key.FollowingUsers.rawValue) }
        
    }
    
    func recordIDForFollowingUser(user: CKUsers) -> CKRecordID {
        let currentUserRecordName = String(recordID.recordName.characters.dropFirst())
        let userRecordName = String(user.recordID.recordName.characters.dropFirst())
        let name = "\(currentUserRecordName)-\(LinkType.UserFollowUser.rawValue)-\(userRecordName)"
        return CKRecordID(recordName: name)
    }

    
    // MARK: - CKQuery
    
    var postedExperimentsQuery: CKQuery {
        return CKQuery(recordType: .Experiment, predicate: postedExperimentsQueryPredicate)
    }
    
    private var postedExperimentsQueryPredicate: NSPredicate {
        return NSPredicate(format: "%K = %@", RecordKey.creatorUserRecordID.rawValue, recordID)
    }
    
    var likedExperimentsQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: likedExperimentsQueryPredicate)
    }
    
    private var likedExperimentsQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue ,LinkType.UserLikeExperiment.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", RecordKey.creatorUserRecordID.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
    }
   
    var followingUsersQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: followingUsersQueryPredicate)
    }
    
    private var followingUsersQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue ,LinkType.UserFollowUser.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", RecordKey.creatorUserRecordID.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
    }
    
    var followersQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: followersQueryPredicate)
    }
    
    private var followersQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue ,LinkType.UserFollowUser.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@",  LinkKey.toUserRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
    }
    
    
    // MARK: - Save
    
    override func saveInBackground(didSave didSave: (Void -> Void)?, didFail: ((NSError) -> Void)?) {
        CKUsers.PostCurrentUserHasChangeNotification()
        CKUsers.GetCurrentUser(
            didGet: {
                currentUser in
                for key in self.changedKeys {
                    currentUser[key] = self[key]
                }
                
                currentUser.superSaveInBackground(
                    didSave: {
                        CKUsers.CurrentUser?.record = currentUser.record
                        CKUsers.saveCurrentUser()
                        didSave?()
                    },
                    
                    didFail: {
                        CKUsers.UpdateCurrentUserFromiCloudKVS()
                        didFail?($0)
                    }
                )
            },
            didFail: {
                CKUsers.UpdateCurrentUserFromiCloudKVS()
                didFail?($0)
            }
        )
    }
    
    private func superSaveInBackground(didSave didSave: (Void -> Void)?, didFail: ((NSError) -> Void)?) {
        super.saveInBackground(didSave: didSave, didFail: didFail)
    }
    
    enum Key: String {
        case CurrentUser = "CKUsers.CurrentUser"
        case FollowingUsers = "CKUsers.FollowingUsers"
        case LikedExperiments = "CKUsers.LikedExperiments"
        
    }
    
    private static var publicCloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
}

extension NSError {
    convenience init(description: String) {
        self.init(domain: "Error", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
    }
}

enum UsersKey: String {
    case displayName
    case profileImageAsset
    case aboutMe

}
