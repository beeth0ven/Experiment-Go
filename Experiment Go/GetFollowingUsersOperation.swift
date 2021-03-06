//
//  GetFollowingUsersOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/29/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetFollowingUsersOperation: GetCKItemsOperation {
    
    convenience init(followingUsersFrom user: CKUsers) {
        self.init(type: .Refresh(user.followingUsersQuery))
    }
    
    private var currentPageLinks: [CKLink] { return (currentPageItems as? [CKLink]) ?? [CKLink]() }
    override var currentPageCallBackItems: [CKItem] { return currentPageLinks.flatMap { $0.toUser } }
    
    override func main() {
        let getLinksOperation = type.queryOperationToAttempt
        
        getLinksOperation.recordFetchedBlock = {
            let object = CKItem.ParseRecord($0)
            self.currentPageItems.append(object)
        }
        
        getLinksOperation.queryCompletionBlock = {
            (cursor, error) in
            
            Queue.Main.execute {
                if let error = error { self.didFail?(error) ; return }
                self.getToUsersFormLinks(self.currentPageLinks, cursor: cursor)
            }
            
        }
        
        getLinksOperation.begin()
    }
    
    
    
    func getToUsersFormLinks(links: [CKLink], cursor: CKQueryCursor?) {
        
        let userRecordIDs = links.flatMap { $0.toMe ? nil : $0.toUserRef?.recordID  }.uniqueArray
        
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)

        fetchUsersOperation.perRecordCompletionBlock = {
            (userRecord, _, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            let user = CKItem.ParseRecord(userRecord!) as! CKUsers
            for link in links { if link.toUserRef!.recordID == user.recordID { link.toUser = user } }
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            Queue.Main.execute {
                if let error = self.fetchErrorFrom(error) { self.didFail?(error) ; return }
                self.didGet?(self.currentPageCallBackItems, cursor)
            }
            
        }
        
        fetchUsersOperation.begin()
    }

    
}