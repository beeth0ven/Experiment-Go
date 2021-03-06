//
//  GetNotificationLinksOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetNotificationLinksOperation: GetCKItemsOperation {
    
    convenience init() {
        self.init(type: .Refresh(CKUsers.NotificationLinksQuery))
    }
    
    private var currentPageLinks: [CKLink] { return (currentPageItems as? [CKLink]) ?? [CKLink]() }

    override func main() {
        let getLinksOperation = type.queryOperationToAttempt
        
        getLinksOperation.recordFetchedBlock = {
            let object = CKItem.ParseRecord($0)
            (object as? CKLink)?.toUser = CKUsers.CurrentUser
            self.currentPageItems.append(object)
        }
        
        getLinksOperation.queryCompletionBlock = {
            (cursor, error) in
            Queue.Main.execute {
                if let error = error { self.didFail?(error) ; return }
                self.getUsersAndExperimentsFormLinks(self.currentPageLinks, cursor: cursor)
            }
            
        }
        
        getLinksOperation.begin()
    }

    func getUsersAndExperimentsFormLinks(links: [CKLink], cursor: CKQueryCursor?) {
        
        let userRecordIDs = links.flatMap { $0.createdByMe ? nil : $0.creatorUserRecordID!  }
        let experimentsRecordIDs = links.flatMap { $0.experimentRef?.recordID }
        
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: (userRecordIDs + experimentsRecordIDs).uniqueArray)

        fetchUsersOperation.perRecordCompletionBlock = {
            (record, _, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            let item = CKItem.ParseRecord(record!)
            for link in links {
                if link.creatorUserRecordID == item.recordID {
                    link.creatorUser = item as? CKUsers
                } else if link.experimentRef?.recordID == item.recordID {
                    link.experiment = item as? CKExperiment
                }
            }
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            Queue.Main.execute {
                if let error = self.fetchErrorFrom(error) { self.didFail?(error) ; return }
                self.didGet?(self.currentPageCallBackItems.filter { $0.completed }, cursor)
            }
            
        }
        
        fetchUsersOperation.begin()
    }
}