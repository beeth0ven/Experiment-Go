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
    
    convenience init(likedBy user: CKUsers) {
        self.init(type: .Refresh(user.likedExperimentsQuery))
    }
    
    private var currentPageLinks: [CKLink] { return (currentPageItems as? [CKLink]) ?? [CKLink]() }
    override var currentPageCallBackItems: [CKItem] { return currentPageLinks.flatMap { $0.experiment } }

    
    override func main() {
        let getLinksOperation = type.queryOperationToAttempt
        
        getLinksOperation.recordFetchedBlock = {
            let object = CKItem.ParseRecord($0) as! CKLink
            self.currentPageItems.append(object)
        }
        
        getLinksOperation.queryCompletionBlock = {
            (cursor, error) in
            Queue.Main.execute {
                if let error = error { self.didFail?(error) ; return }
                self.getExperimentsFormLinks(self.currentPageLinks, cursor: cursor)
            }
            
        }
        
        getLinksOperation.begin()
    }
    
    func getExperimentsFormLinks(links: [CKLink], cursor: CKQueryCursor?) {
        
        let recordIDs = links.map { $0.experimentRef!.recordID }.uniqueArray
        
        let getExperimentsOperation = CKFetchRecordsOperation(recordIDs: recordIDs)

        getExperimentsOperation.perRecordCompletionBlock = {
            (experimentRecord, _, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            let experiment = CKItem.ParseRecord(experimentRecord!) as! CKExperiment
            for link in links { if link.experimentRef?.recordID == experiment.recordID { link.experiment = experiment } }
        }
        
        getExperimentsOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            Queue.Main.execute {
                if let error = self.fetchErrorFrom(error) { self.didFail?(error) ; return }
                self.getUsersFormItems(self.currentPageLinks.flatMap { $0.experiment }, cursor: cursor)
            }
        }
        
        getExperimentsOperation.begin()
    }
}