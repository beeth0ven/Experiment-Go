//
//  GetObjectsWithCreatorUserOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetObjectsWithCreatorUserOperation: GetCKItemsOperation {
    

    override func main() {
        let getObjectsOperation = type.queryOperationToAttempt
        getObjectsOperation.resultsLimit = CKQueryOperation.DafaultResultsLimit
        
        getObjectsOperation.recordFetchedBlock = {
            let object = CKItem.ParseRecord($0)
            self.currentPageItems.append(object)
        }
        
        getObjectsOperation.queryCompletionBlock = {
            (cursor, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { self.didFail?(error) ; return }
                self.getUsersFormItems(self.currentPageItems, cursor: cursor)
            }
            
            
        }
        
        getObjectsOperation.begin()
    }
    
    
    
    func getUsersFormItems(items: [CKItem], cursor: CKQueryCursor?) {
        
        let userRecordIDs = items.flatMap { $0.createdByMe ? nil : $0.creatorUserRecordID!  }
    
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (userRecord, _, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            let user = CKItem.ParseRecord(userRecord!) as! CKUsers
            for item in items { if item.creatorUserRecordID == user.recordID { item.creatorUser = user } }
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.fetchErrorFrom(error)  { self.didFail?(error) ; return }
                self.didGet?(self.currentPageCallBackItems, cursor)
            }
            
        }
        
        fetchUsersOperation.begin()
    }
}

extension CKQueryOperation {
    static var DafaultResultsLimit: Int { return 30 }
}