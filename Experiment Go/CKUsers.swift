//
//  CKUsers.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit



class CKUsers: CKItem {
    
    override var recordID: CKRecordID  { return (recordIDName == CKOwnerDefaultName && CKUsers.CurrentUser?.recordID != nil) ? CKUsers.CurrentUser!.recordID : super.recordID }
    
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
    
    static var ProfileImage: UIImage = StyleKit.imageOfUser
    
    // MARK: - Current User

    static var CurrentUser: CKUsers? = CurrentUserFromiCloudKVS
    
    static func saveCurrentUser() {
        iCloudKeyValueStore.setData(CurrentUser?.archivedData(), forKey: Key.CurrentUser.rawValue)
        iCloudKeyValueStore.synchronize()
    }
    
    static func UpdateCurrentUserFromiCloudKVS() {
        guard let user = CurrentUserFromiCloudKVS else { CurrentUser = nil ; return }
        if CurrentUser == nil { CurrentUser = user } else { CurrentUser?.record = user.record }
        PostCurrentUserHasChangeNotification()
    }
    
    static func UpdateCurrentUser() {
        GetCurrentUser(
            didGet: {
                print($0.recordIDName)
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
            FetchingCurrentUser = false
            Queue.Main.execute { error != nil ? didFail?(error!) : didGet( CKUsers(record: userRecord!)) }
        }
        
        fetchCurrentUserRecordOperation.begin()
    }
    private static var FetchingCurrentUser = false


    private static var iCloudKeyValueStore = NSUbiquitousKeyValueStore.defaultStore()
    private static var notificationCenter = NSNotificationCenter.defaultCenter()
    
    static var HasCloudWritePermision: Bool {
        guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return false } // Login iCloud
        guard UserDiscoverability == true else { return false }                                 // Request Permision
        guard !String.isBlank(CurrentUser?.displayName) else { return false }                   // Set Display Name
        return true                                                                             // All Done
    }
    
    static var UserDiscoverability: Bool? {
        get {
            return iCloudKeyValueStore.objectForKey(Key.UserDiscoverability.rawValue) as? Bool
        }
        
        set {
            iCloudKeyValueStore.setObject(newValue, forKey: Key.UserDiscoverability.rawValue)
            iCloudKeyValueStore.synchronize()
        }
        
    }
    
    private static var RequestingDiscoverabilityInProgress = false
    static func GetDiscoverabilityPermission(didGet didGet: (Bool) -> (), didFail: ((NSError) -> ())?) {
        guard RequestingDiscoverabilityInProgress == false else { return }
        RequestingDiscoverabilityInProgress = true
        CKContainer.defaultContainer().requestApplicationPermission(.UserDiscoverability) {
            applicationPermissionStatus, error in
            RequestingDiscoverabilityInProgress = false
            Queue.Main.execute {
                guard error == nil else { didFail?(error!) ; return }
                let discoverability = applicationPermissionStatus == .Granted
                UserDiscoverability = discoverability
                didGet( discoverability )
            }
        }
    }

    static func SetUserDisplayName(name: String, didSet: (() -> Void), didFail: ((NSError) -> Void)?) {
        GetCurrentUser(
            didGet: {
                currentUser in
                currentUser.displayName = name
                
                currentUser.superSaveInBackground(
                    didSave: {
                        CKUsers.CurrentUser = currentUser
                        CKUsers.saveCurrentUser()
                        didSet()
                    },
                    
                    didFail: didFail
                )
            },
            
            didFail: didFail
        )
    }
    
    // MARK: - Liked Experiments
    
    static func AmILikingThisExperiment(experiment: CKExperiment) -> Bool {
        return LikedExperiments.contains(experiment.recordID.recordName)
    }
    
    static func LikeExperiment(experiment: CKExperiment, didLike: (Void -> Void)? = nil, didFail: ((NSError) -> Void)? = nil) {
        guard LikeOperationInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
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
        guard LikeOperationInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
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
        guard FollowOperationInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
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
        guard FollowOperationInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
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

    // MARK: - Search Users
    static func GetUser(email email: String, didGet: ((CKUsers) -> Void)?, didFail: ((NSError) -> Void)?) {
        guard GetUserInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
        GetUserInProgress = true
        let discoverUserInfosOperation = CKDiscoverUserInfosOperation(emailAddresses: [email], userRecordIDs: nil)

        discoverUserInfosOperation.discoverUserInfosCompletionBlock = {
            userInfoByEmail, userInfoByRecordID, error in
            GetUserInProgress = false
            Queue.Main.execute {
                if let error = error { didFail?(error) ; return }
                guard let recordID =  userInfoByEmail![email]?.userRecordID else { didFail?(ErrorType.UserByEmailNotFound.error) ; return }
                GetItem(recordID: recordID, didGet: { didGet?($0 as! CKUsers) }, didFail: didFail)
            }
        }
        
        discoverUserInfosOperation.qualityOfService = .UserInitiated
        discoverUserInfosOperation.start()
    }
    
    private static var GetUserInProgress = false

    static func GetUsersFromContacts(didGet didGet: (([CKUsers]) -> Void)?, didFail: ((NSError) -> Void)?) {
        guard GetUserInProgress == false else { didFail?(NSError(errorType: .ServerBusy)) ; return }
        GetUserInProgress = true
        let discoverUserInfosOperation = CKDiscoverAllContactsOperation()
        discoverUserInfosOperation.discoverAllContactsCompletionBlock = {
            userInfos, error in
            GetUserInProgress = false
            Queue.Main.execute {
                if let error = error { didFail?(error) ; return }
                let recordIDs = userInfos!.flatMap { $0.userRecordID }
                guard recordIDs.count > 0 else { didFail?(ErrorType.UsersFromContactsNotFound.error) ; return }
                GetItems(recordIDs: recordIDs, didGet: { didGet?($0 as! [CKUsers]) }, didFail: didFail)
            }
        }
        
        discoverUserInfosOperation.qualityOfService = .UserInitiated
        discoverUserInfosOperation.start()
    }
    
    private enum ErrorType {
        case UserByEmailNotFound
        case UsersFromContactsNotFound
        
        var error: NSError {
            var description: String
            switch self {
            case .UserByEmailNotFound:
                description = "User Not Found."
            case .UsersFromContactsNotFound:
                description = "Users Not Found."
            }
            return NSError(description: NSLocalizedString(description, comment: ""))
        }
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
    
    static var CurrentUserInteretedExperimentsQuery: CKQuery {
        return CKQuery(recordType: .Experiment, predicate: CurrentUserInteretedExperimentsQueryPredicate)
    }
    
    static private var CurrentUserInteretedExperimentsQueryPredicate: NSPredicate {
        let userRecordNames: [String] = CKUsers.CurrentUser != nil ? FollowingUsers + [CKUsers.CurrentUser!.recordID.recordName] : FollowingUsers
        let recordRefs = userRecordNames.map {  CKReference(recordID: CKRecordID(recordName: $0), action: .DeleteSelf)  }
        return NSPredicate(format: "%K IN %@", RecordKey.creatorUserRecordID.rawValue ,recordRefs)
    }
    
    static var NotificationLinksQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: NotificationLinksQueryPredicate)
    }
    
    static private var NotificationLinksQueryPredicate: NSPredicate {
        let recordID = CKUsers.CurrentUser != nil ? CKUsers.CurrentUser!.recordID : CKRecordID.NotFoundID
        return NSPredicate(format: "%K == %@", LinkKey.toUserRef.rawValue, recordID)
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
    
    var followersQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue ,LinkType.UserFollowUser.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@",  LinkKey.toUserRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
    }
    
    // MARK: - CKSubscription
    static func saveCurrentUserSubscriptionsIfNeeded() {
        guard HasSaveCurrentUserSubscription == false && CurrentUser != nil else { return }
        let op = CKModifySubscriptionsOperation(subscriptionsToSave: currentUserSubscriptions, subscriptionIDsToDelete: nil)
        op.modifySubscriptionsCompletionBlock = { if $2 == nil { HasSaveCurrentUserSubscription = true } }
        op.begin()
    }
    
    private static var currentUserSubscriptions: [CKSubscription] {
        let reviewsSubscription = CKSubscription(reviewsTo: CurrentUser!)
        let fansSubscription = CKSubscription(fansTo: CurrentUser!)
        let followersSubscription = CKSubscription(followersTo: CurrentUser!)
        return [reviewsSubscription, fansSubscription, followersSubscription]
    }
    
    private static var HasSaveCurrentUserSubscription: Bool {
        get { return iCloudKeyValueStore.objectForKey(Key.HasSaveCurrentUserSubscription.rawValue) as? Bool ?? false }
        set { iCloudKeyValueStore.setObject(newValue, forKey:Key.HasSaveCurrentUserSubscription.rawValue) ; iCloudKeyValueStore.synchronize() }
    }
    
    var reviewsQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue, LinkType.UserReviewToExperiment.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", LinkKey.toUserRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [typePredicate, userPredicate])
    }
    
    var fansQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue, LinkType.UserLikeExperiment.rawValue)
        let userPredicate = NSPredicate(format: "%K = %@", LinkKey.toUserRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [typePredicate, userPredicate])
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
                print("Before Save: \(NSDate().string)")
                currentUser.superSaveInBackground(
                    didSave: {
                        print("Did Save: \(NSDate().string)")
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
        case UserDiscoverability = "CKUsers.UserDiscoverability"
        case HasSaveCurrentUserSubscription = "CKUsers.HasSaveCurrentUserSubscription"
        
    }
    
    private static var publicCloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
}

extension NSError {
    
    convenience init(description: String) {
        self.init(domain: "Error", code: 100, userInfo: [NSLocalizedDescriptionKey: description])
    }
    
    convenience init(errorType: ErrorType) {
        self.init(description: errorType.localizedDescription)
    }
    
    enum ErrorType {
        case ServerBusy

        var localizedDescription: String {
            var description: String
            switch self {
            case .ServerBusy:
                description = "Server is busy, Please retry later."
            }
            return NSLocalizedString(description, comment: "")
        }
    }
}

extension CKRecordID {
    static var NotFoundID: CKRecordID { return CKRecordID(recordName: "__NOT_FOUND__") }
}

enum UsersKey: String {
    case displayName
    case profileImageAsset
    case aboutMe

}

extension CKSubscription {
    convenience init(reviewsTo user: CKUsers) {
        let reviewsSubscriptionID = "\(user.recordIDNameToSave)-reviews-subscription"
        self.init(
            recordType: RecordType.Link.rawValue,
            predicate: user.reviewsQueryPredicate,
            subscriptionID: reviewsSubscriptionID,
            options: .FiresOnRecordCreation
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "New review to your experiment!"
        
        self.notificationInfo = notificationInfo
    }
    
    convenience init(fansTo user: CKUsers) {
        let fansSubscriptionID = "\(user.recordIDNameToSave)-fans-subscription"
        self.init(
            recordType: RecordType.Link.rawValue,
            predicate: user.fansQueryPredicate,
            subscriptionID: fansSubscriptionID,
            options: .FiresOnRecordCreation
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "New fan to your experiment!"
        
        self.notificationInfo = notificationInfo
    }
    
    convenience init(followersTo user: CKUsers) {
        let followersSubscriptionID = "\(user.recordIDNameToSave)-followers-subscription"
        self.init(
            recordType: RecordType.Link.rawValue,
            predicate: user.followersQueryPredicate,
            subscriptionID: followersSubscriptionID,
            options: .FiresOnRecordCreation
        )
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "New follower!"
        
        self.notificationInfo = notificationInfo
    }
}
