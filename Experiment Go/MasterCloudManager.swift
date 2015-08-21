//
//  MasterCloudManager.swift
//  Experiment Go
//
//  Created by luojie on 8/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import Foundation
import CloudKit

class MasterCloudManager: NSObject {
    var experiments = [[CKRecord]]()
    var currentPageExperiments = [CKRecord]()

    var userCache: NSCache {
        return AppDelegate.Cache.Manager.userCache
    }
    
    
    var lastQueryCursor: CKQueryCursor?
    
    
    var moreComing: Bool {
        return nextPageToQuery != nil ? true : false
    }
    
    var nextPageToQuery: CKQueryOperation? {
        if let lastQueryCursor = lastQueryCursor {
            return CKQueryOperation(cursor: lastQueryCursor)
        } else {
            return nil
        }
    }
    
    private var loadingPage = false

    // MARK: - Help
    func userForExperiment(experiment: CKRecord) -> CKRecord? {
        let userRecordID = experiment.valueForKey(RecordKey.CreatorUserRecordID) as! CKRecordID
        print("userForExperiment: \(userRecordID.recordName)")
        return userCache.objectForKey(userRecordID.recordName) as? CKRecord
    }

    
    // MARK: - Fetch data from cloud

    func refreshData(completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        
        experiments = [[CKRecord]]()
        currentPageExperiments = [CKRecord]()

        let queryOperation = CKQueryOperation(recordType: ExperimentKey.RecordType)
        
        queryOperation.recordFetchedBlock = experimentFetchedBlock
        
        queryOperation.queryCompletionBlock = {
            (cursor, error) in
            dispatch_async(dispatch_get_main_queue()) {
                guard error == nil else {  handleError?(error!) ; return }
                self.lastQueryCursor = cursor
                self.experiments.append(self.currentPageExperiments)
                completionBlock?(self.currentPageExperiments)
            }
        }
        
        publicCloudDatabase.addOperation(queryOperation)
        
    }
    
    
    func fetchNextPage(completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        guard moreComing  && loadingPage == false else { return }
        loadingPage = true
        
        currentPageExperiments = [CKRecord]()

        let queryOperation = nextPageToQuery!
        queryOperation.recordFetchedBlock = experimentFetchedBlock
        
        queryOperation.queryCompletionBlock = {
            (cursor, error) in
            dispatch_async(dispatch_get_main_queue()) {
                guard error == nil else {  self.loadingPage = false ; handleError?(error!) ; return }
                self.lastQueryCursor = cursor
                self.loadingPage = false
                self.experiments.append(self.currentPageExperiments)
                completionBlock?(self.currentPageExperiments)
            }
        }
        
        publicCloudDatabase.addOperation(queryOperation)
    }
    
    lazy var experimentFetchedBlock: (CKRecord) -> Void = {
        [unowned self] (experiment) in
        self.currentPageExperiments.append(experiment)
    }
    
    func fetchUsersFrom(experiments: [CKRecord],completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        guard experiments.count > 0 else { return }
        var userRecordIDs = Array(Set(experiments.map { $0.valueForKey(RecordKey.CreatorUserRecordID) as! CKRecordID }))
        userRecordIDs = userRecordIDs.filter { $0.recordName != CKOwnerDefaultName }
        
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (user, userRecordID, error) in
            guard error == nil else { return print(error!.localizedDescription)  }
            self.userCache.setObject(user!, forKey: userRecordID!.recordName)
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (result, error) in
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue()) {
                    handleError?(error!)
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                let userRecords = result!.values.array
                completionBlock?(userRecords)
            }
            
        }
        
        publicCloudDatabase.addOperation(fetchUsersOperation)
    }
    
    
}