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
    // MARK: - Cloud Kit Stack
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
    
    private var isLoadingLikeState = false
    
    func amILikingThisExperiment(experiment: CKRecord, completionHandler: (Bool) -> ()) {
        guard isLoadingLikeState == false else { print("Another query is in a progress to load like state.") ; return }
        isLoadingLikeState = true
        let keyPredicate = NSPredicate(format: "%K = %@", FanLinkKey.ToExperiment, experiment)
        let authorPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, currentUser!.recordID)
        let predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [keyPredicate,authorPredicate])
        let query = CKQuery(recordType: FanLinkKey.RecordType, predicate: predicate)
        publicCloudDatabase.performQuery(query, inZoneWithID: nil) { (records, error)  in
            self.isLoadingLikeState = false
            guard error == nil else { return }
            let liking = records!.count > 0
            dispatch_async(dispatch_get_main_queue()) { completionHandler(liking) }
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

struct FanLinkKey {
    static let RecordType = "FanLink"
    static let ToExperiment = "toExperiment"
}

