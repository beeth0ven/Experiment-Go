//
//  GetExperimentsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetExperimentsOperation: GetCKObjectsOperation {
    
    private var currentPageExperiments  = [CKExperiment]()

    override func main() {
        currentPageExperiments.removeAll()
        let getExperimentsOperation = type.queryOperationToAttempt
        getExperimentsOperation.recordFetchedBlock = {
            let experiment = CKExperiment(record: $0)
            self.currentPageExperiments.append(experiment)
            if experiment.creatorUserRecordID!.recordName == CKOwnerDefaultName {
                let currentUser = CKUsers(record:AppDelegate.Cloud.Manager.currentUser!)
                experiment.creatorUser = currentUser
            }
        }
        
        getExperimentsOperation.queryCompletionBlock = {
            (cursor, error) in
            if let error = error { self.didFail?(error) ; return }
            self.getUsersFormExperimnets(self.currentPageExperiments, cursor: cursor)
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(getExperimentsOperation)
    }
    
    

    private func getUsersFormExperimnets(experimnets: [CKExperiment], cursor: CKQueryCursor?) {
        
        let userRecordIDs = experimnets.flatMap { $0.creatorUser == nil ? $0.creatorUserRecordID! : nil }
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (userRecord, _, _) in
            let user = CKUsers(record: userRecord!)
            for experiment in experimnets {
                if experiment.creatorUserRecordID == user.recordID { experiment.creatorUser = user }
            }
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { self.didFail?(error) ; return }
                self.didGet?(experimnets, cursor)
            }
            
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(fetchUsersOperation)
    }
    
    

}