//
//  GetUserLikedExperimentsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class GetUserLikedExperimentsOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(likedBy: CKUsers) {
        self.init(type: .Refresh(likedBy.likedExperimentsQuery))
    }
    
    private var currentPageLinks  = [CKLink]()
    
    override func main() {
        let getLinksOperation = type.queryOperationToAttempt
        getLinksOperation.resultsLimit = CKQueryOperation.DafaultResultsLimit
        
        getLinksOperation.recordFetchedBlock = {
            let object = CKItem.parseRecord($0) as! CKLink
            self.currentPageLinks.append(object)
        }
        
        getLinksOperation.queryCompletionBlock = {
            (cursor, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { self.didFail?(error) ; return }
                self.getExperimentsFormLinks(self.currentPageLinks, cursor: cursor)
            }
            
        }
        
        getLinksOperation.begin()
    }
    
    func getExperimentsFormLinks(links: [CKLink], cursor: CKQueryCursor?) {
        
        let recordIDs = links.map { $0.experimentRef!.recordID }
        
        let getExperimentsOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
        
        getExperimentsOperation.perRecordCompletionBlock = {
            (experimentRecord, _, _) in
            let experiment = CKItem.parseRecord(experimentRecord!) as! CKExperiment
            self.currentPageItems.append(experiment)
        }
        
        getExperimentsOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { self.didFail?(error) ; return }
                self.getUsersFormItems(self.currentPageItems, cursor: cursor)
            }
            
        }
        
        getExperimentsOperation.begin()
    }
}