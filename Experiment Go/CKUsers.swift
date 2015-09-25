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
    
    static var currentUser: CKUsers? = currentUserFromiCloudKVS
    
    static func saveCurrentUser() {
        iCloudKeyValueStore.setData(currentUser?.archivedData(), forKey: Key.currentUser.rawValue)
        iCloudKeyValueStore.synchronize()
    }
    
    static func rollBackCurrentUser() {
        guard let user = currentUserFromiCloudKVS else { currentUser = nil ; return }
        currentUser?.record = user.record
        postCurrentUserHasChangeNotification()
    }

    private static var currentUserFromiCloudKVS: CKUsers? {
        guard let data = iCloudKeyValueStore.dataForKey(Key.currentUser.rawValue) else { return nil }
        return CKUsers(data: data)
    }
    
    static func postCurrentUserHasChangeNotification() {
        notificationCenter.postNotificationName(Notification.currentUserHasChange.rawValue, object: nil)
    }
    
    private static var iCloudKeyValueStore = NSUbiquitousKeyValueStore.defaultStore()
    private static var notificationCenter = NSNotificationCenter.defaultCenter()
    
    override var displayTitle: String? { return displayName }
    
    var isMe: Bool  { return recordID.recordName == CKOwnerDefaultName || recordID.recordName == CKUsers.currentUser?.recordID.recordName }
    
    static func updateCurrentUser() { getCurrentUser( didGet: { self.currentUser?.record = $0.record ; saveCurrentUser() } ) }
    
    private static var isFetchingCurrentUser = false
    static func getCurrentUser(didGet didGet: (CKUsers) -> (), didFail: ((NSError) -> ())? = nil) {
        guard isFetchingCurrentUser == false else { return }
        isFetchingCurrentUser = true
        let fetchCurrentUserRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
        fetchCurrentUserRecordOperation.perRecordCompletionBlock = {
            (userRecord, _, error) in
            self.isFetchingCurrentUser = false
            dispatch_async(dispatch_get_main_queue()) {
                guard  error == nil else { didFail?(error!) ; return }
                didGet( CKUsers(record: userRecord!) )
            }
        }
        publicCloudDatabase.addOperation(fetchCurrentUserRecordOperation)
    }
    
    static func getCurrentUserProfileImageIfNeeded() {
        guard needGetCurrentUserProfileImage else { return }
        getCurrentUser(
            didGet: {
                currentUser in
                let url = currentUser.profileImageAsset!.fileURL
                UIImage.getImageForURL(url,
                    didGet: { (_) in notificationCenter.postNotificationName(Notification.currentUserHasChange.rawValue, object: nil) }
                )
            }
        )
    }
    
    static private var needGetCurrentUserProfileImage: Bool {
        if let url = currentUser?.profileImageAsset?.fileURL {
            if AppDelegate.Cache.Manager.assetDataForURL(url) == nil { return true }
        }
        return false
    }
    
    
    override func saveInBackground(didSave didSave: (Void -> Void)?, didFail: ((NSError) -> Void)?) {
        CKUsers.postCurrentUserHasChangeNotification()
        CKUsers.getCurrentUser(
            didGet: {
                currentUser in
                for key in self.changedKeys { currentUser[key] = self[key] }
                
                currentUser.superSaveInBackground(
                    didSave: {
                        CKUsers.currentUser?.record = currentUser.record
                        CKUsers.saveCurrentUser()
                        didSave?()
                    },
                    
                    didFail: {
                        CKUsers.rollBackCurrentUser()
                        didFail?($0)
                    }
                )
            },
            didFail: {
                CKUsers.rollBackCurrentUser()
                didFail?($0)
            }
        )
    }
    
    private func superSaveInBackground(didSave didSave: (Void -> Void)?, didFail: ((NSError) -> Void)?) {
        super.saveInBackground(didSave: didSave, didFail: didFail)
    }
    
    private enum Key: String {
        case currentUser = "CKUsers.currentUser"
    }
    
    private static var publicCloudDatabase = CKContainer.defaultContainer().publicCloudDatabase

}

enum UsersKey: String {
    case displayName
    case profileImageAsset
    case aboutMe

}
