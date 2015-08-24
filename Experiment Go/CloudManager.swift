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
    struct Notification {
        static let CurrentUserDidChange = "CloudManager.Notification.CurrentUserDidChange"
    }
    
    // MARK: - Cloud Kit Stack
    
    var publicCloudDatabase: CKDatabase {
        return CKContainer.defaultContainer().publicCloudDatabase
    }
    
    init() {
        self.updateCurrentUser()
    }
    
    var currentUser: CKRecord? {
        didSet {
            if oldValue != currentUser {
                if oldValue != nil { userCache.removeObjectForKey(oldValue!.recordID.recordName) }
                if currentUser != nil { userCache.setObject(currentUser!, forKey: CKOwnerDefaultName) ; print("cache currentUser: \(currentUser!.recordID.recordName)")}
                NSNotificationCenter.defaultCenter().postNotificationName(Notification.CurrentUserDidChange, object: nil)
            }
        }
    }
    
    var userCache: NSMutableDictionary {
        return AppDelegate.Cache.Manager.userCache
    }
    
    
    private func updateCurrentUser() {
        requestDiscoverabilityPermission { (granted) in
            guard granted else { abort() }
            self.fetchCurrentUser() { (user) in
                self.currentUser = user
//                let recordID = self.currentUser!.valueForKey(RecordKey.RecordID) as! CKRecordID
//                print("currentUser name: \(recordID.recordName))")
//                print("currentUser zoneName: \(recordID.zoneID.zoneName))")

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
    

}

protocol CKRecordConvertible: class {
    var recordID: String? { get set }
    var creationDate: NSDate? { get set }
    var creatorUserRecordID: String? { get set }
    var modificationDate: NSDate? { get set }
    var lastModifiedUserRecordID: String? { get set }
    var recordChangeTag: String? { get set }
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
    static let WhoPost = "whoPost"
}

struct RecordKey {
    static let RecordID = "recordID"
    static let CreationDate = "creationDate"
    static let CreatorUserRecordID = "creatorUserRecordID"
    static let ModificationDate = "modificationDate"
    static let LastModifiedUserRecordID = "lastModifiedUserRecordID"
    static let RecordChangeTag = "recordChangeTag"
}


