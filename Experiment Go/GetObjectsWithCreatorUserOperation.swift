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
        
        getObjectsOperation.recordFetchedBlock = {
            let object = CKItem.ParseRecord($0)
            self.currentPageItems.append(object)
        }
        
        getObjectsOperation.queryCompletionBlock = {
            (cursor, error) in
            Queue.Main.execute {
                if let error = error { self.didFail?(error) ; return }
                self.getUsersFormItems(self.currentPageItems, cursor: cursor)
            }
            
        }
        
        getObjectsOperation.begin()
    }
    
    
    
    func getUsersFormItems(items: [CKItem], cursor: CKQueryCursor?) {
        
        let userRecordIDs = items.flatMap { $0.createdByMe ? nil : $0.creatorUserRecordID!  }.uniqueArray
    
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        userRecordIDs.forEach { print($0.recordName) }
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (userRecord, _, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            let user = CKItem.ParseRecord(userRecord!) as! CKUsers
            for item in items { if item.creatorUserRecordID == user.recordID { item.creatorUser = user } }
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            Queue.Main.execute {
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

extension Array where Element : Hashable {
    var uniqueArray: Array { return Array(Set(self)) }
}


enum Queue {
    case Main
    case UserInteractive
    case UserInitiated
    case Utility
    case Background
    
    func execute(closure: () -> Void) { dispatch_async(queue, closure) }
    
    private var queue: dispatch_queue_t {
        
        switch self {
        case .Main:
            return dispatch_get_main_queue()
        case .UserInteractive:
            return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        case .UserInitiated:
            return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
        case .Utility:
            return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        case .Background:
            return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        }
    }

}

