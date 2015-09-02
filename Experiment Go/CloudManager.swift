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


class CloudManager {
    // MARK: - Update Current User
    
    var publicCloudDatabase: CKDatabase {
        return CKContainer.defaultContainer().publicCloudDatabase
    }
    
    private var currentUser: CKRecord? {
        return AppDelegate.Cache.Manager.currentUser()
    }
    
    func updateCurrentUser(completionHandler: (CKRecord) -> Void) {
        requestDiscoverabilityPermission { (granted) in
            guard granted else { abort() }
            self.fetchCurrentUser() { (user) in
                AppDelegate.Cache.Manager.cacheCurrentUser(user)
                completionHandler(user)
            }
        }
    }
    
    private func requestDiscoverabilityPermission(completionHandler: (Bool) -> ()) {
        CKContainer.defaultContainer().requestApplicationPermission(.PermissionUserDiscoverability) { (applicationPermissionStatus, error) -> Void in
            guard  error == nil else { print(error!.localizedDescription) ; abort() }
            dispatch_async(dispatch_get_main_queue()) { completionHandler( applicationPermissionStatus == .Granted ) }
        }
    }
    
    private func fetchCurrentUser(completionHandler: (CKRecord) -> Void) {
        let fetchCurrentUserRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
        fetchCurrentUserRecordOperation.perRecordCompletionBlock = {
            (user, _, error) in
            guard  error == nil else { print(error!.localizedDescription) ; abort() }
            dispatch_async(dispatch_get_main_queue()) { completionHandler( user! ) }
        }
        publicCloudDatabase.addOperation(fetchCurrentUserRecordOperation)
    }
    
    // MARK: - Cloud Key Value Store
    
    func amILikingThisExperiment(experiment: CKRecord) -> Bool {
        return likedExperiments.contains(experiment.recordID.recordName)
    }
    
    func likeExperiment(experiment: CKRecord, completionHandler: (NSError?) -> ()) {
        let fanLink = CKRecord(fanLinktoExperiment: experiment)
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
    
    private let kLikedExperiments = "CloudManager.likedExperiments"

    private var likedExperiments: [String] {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().arrayForKey(kLikedExperiments) as? [String] ?? [String]()
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setArray(newValue, forKey: kLikedExperiments)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    
    func amIFollowingTheUser(user: CKRecord) -> Bool {
        return followingUsers.contains(user.recordID.recordName)
    }
    
    func followUser(user: CKRecord, completionHandler: (NSError?) -> ()) {
        let followLink = CKRecord(followLinktoUser: user)
        
        publicCloudDatabase.saveRecord(followLink) {
            (followLink, error) in
            guard error == nil else { dispatch_async(dispatch_get_main_queue()) { completionHandler(error!) } ; return }
            dispatch_async(dispatch_get_main_queue()) { completionHandler(nil) }
            self.followingUsers = self.followingUsers + [user.recordID.recordName]
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
    
    private let kFollowingUsers = "followingUsers"
    
    private var followingUsers: [String] {
        
        get {
            return NSUbiquitousKeyValueStore.defaultStore().arrayForKey(kFollowingUsers) as? [String] ?? [String]()
        }
        
        set {
            NSUbiquitousKeyValueStore.defaultStore().setArray(newValue, forKey: kFollowingUsers)
            NSUbiquitousKeyValueStore.defaultStore().synchronize()
        }
        
    }
    
    
}

// MARK: - Cloud Kit Record Key

struct RecordKey {
    static let RecordID = "recordID"
    static let CreationDate = "creationDate"
    static let CreatorUserRecordID = "creatorUserRecordID"
    static let ModificationDate = "modificationDate"
    static let LastModifiedUserRecordID = "lastModifiedUserRecordID"
    static let RecordChangeTag = "recordChangeTag"
}

struct UserKey {
    static let RecordType = "User"
    static let ProfileImageAsset = "profileImageAsset"
    static let DisplayName = "displayName"
    static let AboutMe = "aboutMe"
    
}

struct ExperimentKey {
    static let RecordType = "Experiment"
    static let Title = "title"
    static let Body = "body"
    static let Reviews = "reviews"
    static let Fans = "fans"
}

struct ReviewKey {
    static let RecordType = "Review"
    static let Body = "body"
    static let ReviewTo = "reviewTo"

}

struct LinkKey {
    static let RecordType = "Link"
    static let LinkType = "linkType"
    static let To = "to"
}

enum RecordType: String {
    case Experiment
    case Review
    case Link
    case User
}

enum LinkType: String {
    case UserLikeExperiment
    case UserFollowUser
}

extension CKRecord {
    convenience init(fanLinktoExperiment experiment: CKRecord) {
        let recordID = CKRecordID(fanLinktoExperiment: experiment)
        self.init(linkType: LinkType.UserLikeExperiment, recordID: recordID)
        self[LinkKey.To] = CKReference(record: experiment, action: .DeleteSelf)
    }
    
    convenience init(followLinktoUser user: CKRecord) {
        let recordID = CKRecordID(followLinktoUser: user)
        self.init(linkType: LinkType.UserFollowUser, recordID: recordID)
        self[LinkKey.To] = CKReference(record: user, action: .DeleteSelf)

    }

    convenience init(linkType: LinkType, recordID: CKRecordID) {
        self.init(recordType: LinkKey.RecordType, recordID: recordID)
        self[LinkKey.LinkType] = linkType.rawValue
    }
    
    var smartStringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.smartStringFormDate(date)
    }
    
    var stringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
    }
}


extension CKRecordID {
    convenience init(fanLinktoExperiment experiment: CKRecord) {
        let currentUser = AppDelegate.Cache.Manager.currentUser()!
        let userRecordName = String(dropFirst(currentUser.recordID.recordName.characters))
        let name = "\(userRecordName)-\(LinkType.UserLikeExperiment.rawValue)-\(experiment.recordID.recordName)"
        self.init(recordName: name)
        print(name)
    }
    
    convenience init(followLinktoUser user: CKRecord) {
        let currentUser = AppDelegate.Cache.Manager.currentUser()!
        let currentUserRecordName = String(dropFirst(currentUser.recordID.recordName.characters))
        let userRecordName = String(dropFirst(user.recordID.recordName.characters))
        let name = "\(currentUserRecordName)-\(LinkType.UserFollowUser.rawValue)-\(userRecordName)"
        self.init(recordName: name)
        print(name)

    }
}


