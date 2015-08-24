//
//  FetchedCKRecordController.swift
//  Experiment Go
//
//  Created by luojie on 8/23/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import Foundation
import CloudKit


class FetchedRecordController: NSObject {
    
//    private struct Constants {
//        static let  DefaultRecordsPerPage = 5
//    }
    
    var fetchedQuery: CKQuery
    var recordsPerPage: Int
    var includeCreatorUser: Bool

    var fetchedRecords = [[CKRecord]]()
    var currentPageRecords = [CKRecord]()
    private var currentQueryCursor: CKQueryCursor?

    
    init(fetchedQuery: CKQuery, recordsPerPage: Int, includeCreatorUser: Bool) {
        self.fetchedQuery = fetchedQuery
        self.recordsPerPage = recordsPerPage
        self.includeCreatorUser = includeCreatorUser
    }
    
    
    private var lastQueryCursor: CKQueryCursor?

    
    var moreComing: Bool {
        return nextPageToQuery != nil ? true : false
    }
    
    private var nextPageToQuery: CKQueryOperation? {
        if let lastQueryCursor = lastQueryCursor {
            return CKQueryOperation(cursor: lastQueryCursor)
        } else {
            return nil
        }
    }
    
    private var loadingPage = false {
        didSet {
            if loadingPage {
                print("Loading Page.")
            } else {
                print("Stop loading Page.")
            }
        }
    }
    
    
    // MARK: - Fetch data from cloud
    
    var shoudRefreshData: Bool {
        guard loadingPage == false  else { print("Shoudn't Refresh Data. A querry is in process.") ; return false }
        return true
    }
    
    func refreshData(completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        guard shoudRefreshData else { return }
        loadingPage = true
        
        fetchedRecords = [[CKRecord]]()
        currentPageRecords = [CKRecord]()
        currentQueryCursor = nil
        
        let queryOperation =  CKQueryOperation(query: fetchedQuery)
        queryOperation.resultsLimit = recordsPerPage
        
        queryOperation.recordFetchedBlock = recordFetchedBlock
        queryOperation.queryCompletionBlock = recordsFetchedBlockFrom(completionBlock, handleError: handleError)
        
        publicCloudDatabase.addOperation(queryOperation)
        
    }
    
    var shouldLoadNextPage: Bool {
        guard moreComing  else { print("have fetched all result.") ; return false  }
        guard loadingPage == false else { print("A querry is in process.") ; return false  }
        return true
    }
    
    func fetchNextPage(completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        guard shouldLoadNextPage else { return }
        
        loadingPage = true
        
        currentPageRecords = [CKRecord]()
        currentQueryCursor = nil

        let queryOperation = nextPageToQuery!
        queryOperation.resultsLimit = recordsPerPage
        queryOperation.recordFetchedBlock = recordFetchedBlock
        queryOperation.queryCompletionBlock = recordsFetchedBlockFrom(completionBlock, handleError: handleError)
        publicCloudDatabase.addOperation(queryOperation)
    }
    
    
    
    
    // MARK: - Block

    lazy var recordFetchedBlock: (CKRecord) -> Void = {
        [weak self] (experiment) in
        guard let weakSelf = self else { return }
        weakSelf.currentPageRecords.append(experiment)
    }
    
    
    private func recordsFetchedBlockFrom(
        completionBlock: (([CKRecord]) -> Void)? ,
        handleError: ((NSError) -> Void)?)
        -> ((CKQueryCursor?, NSError?) -> Void) {
            
            let recordsFetchedBlock: (CKQueryCursor?, NSError?) -> Void = {
                (cursor, error) in
                dispatch_async(dispatch_get_main_queue()) {
                    self.loadingPage = false
                    guard error == nil else { handleError?(error!) ; return }
                    self.currentQueryCursor = cursor
                    guard self.includeCreatorUser == false else { self.fetchUsersFromRecords(self.currentPageRecords, completionBlock: completionBlock, handleError: handleError)  ; return }
                    self.lastQueryCursor = self.currentQueryCursor
                    self.fetchedRecords.append(self.currentPageRecords)
                    completionBlock?(self.currentPageRecords)
                }
            }
            return recordsFetchedBlock
    }
    
    
    func fetchUsersFromRecords(records: [CKRecord],completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        var userRecordIDs = Array(Set(records.map { $0.valueForKey(RecordKey.CreatorUserRecordID) as! CKRecordID }))
        userRecordIDs = userRecordIDs.filter { $0.recordName != CKOwnerDefaultName }
        guard userRecordIDs.count > 0 else { completionBlock?(records) ; return  }
        self.loadingPage = true
        
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (user, userRecordID, error) in
            guard error == nil else { return print(error!.localizedDescription)  }
            let userCache = AppDelegate.Cache.Manager.userCache
            userCache.setObject(user!, forKey: userRecordID!.recordName)
        }
        
        fetchUsersOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            self.loadingPage = false
            
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue()) {
                    handleError?(error!)
                }
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.lastQueryCursor = self.currentQueryCursor
                self.fetchedRecords.append(self.currentPageRecords)
                completionBlock?(records)
            }
            
        }
        
        publicCloudDatabase.addOperation(fetchUsersOperation)
    }
    

    
}

extension CKRecord {
    var createdBy: CKRecord? {
        let userRecordID = self[RecordKey.CreatorUserRecordID] as! CKRecordID
        let userCache = AppDelegate.Cache.Manager.userCache
        return userCache.objectForKey(userRecordID.recordName) as? CKRecord
    }

}

extension CKQueryOperation {
    convenience init(recordType: String) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.CreationDate, ascending: false)]
        self.init(query: query)
    }
}

