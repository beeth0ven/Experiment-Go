//
//  FetchedCKRecordController.swift
//  Experiment Go
//
//  Created by luojie on 8/23/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import Foundation
import CloudKit
import CoreData


@objc protocol FetchedRecordControllerDelegate: class {
    
    optional func controllerWillChangeContent(controller: FetchedRecordController)
    
    optional func controller(controller: FetchedRecordController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    
    optional func controller(controller: FetchedRecordController,
        didChangeSections sections: NSIndexSet,
        forChangeType type: NSFetchedResultsChangeType)
    
    optional func controllerDidChangeContent(controller: FetchedRecordController)

}

class FetchedRecordController: NSObject {
    
    var fetchedQuery: CKQuery
    var recordsPerPage: Int
    var includeCreatorUser: Bool

    var fetchedRecords = [[CKRecord]]()
    var currentPageRecords = [CKRecord]()
    private var currentQueryCursor: CKQueryCursor?
    
    weak var delegate: FetchedRecordControllerDelegate?
    
    
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
        
        let sectionsRange = NSRange(location: 0, length: fetchedRecords.count)

        fetchedRecords = [[CKRecord]]()
        currentPageRecords = [CKRecord]()
        currentQueryCursor = nil
        
        self.delegate?.controllerWillChangeContent?(self)
        self.delegate?.controller?(self, didChangeSections: NSIndexSet(indexesInRange: sectionsRange) , forChangeType: .Delete)
        self.delegate?.controllerDidChangeContent?(self)
        
        let queryOperation =  CKQueryOperation(query: fetchedQuery)
        queryOperation.resultsLimit = recordsPerPage
        
        queryOperation.recordFetchedBlock = recordFetchedBlock
        queryOperation.queryCompletionBlock = recordsFetchedBlockFrom(completionBlock, handleError: handleError)
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(queryOperation)
        
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
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(queryOperation)
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
                   self.callBackBlock()
                }
            }
            return recordsFetchedBlock
    }
    
    lazy var callBackBlock: ()->() = {
        [weak self] in
        guard let weakSelf = self else { return }
        dispatch_async(dispatch_get_main_queue()) {
            weakSelf.lastQueryCursor = weakSelf.currentQueryCursor
            weakSelf.delegate?.controllerWillChangeContent?(weakSelf)
            weakSelf.fetchedRecords.append(weakSelf.currentPageRecords)
            weakSelf.delegate?.controller?(weakSelf, didChangeSections: NSIndexSet(index: weakSelf.fetchedRecords.endIndex - 1) , forChangeType: .Insert)
            weakSelf.delegate?.controllerDidChangeContent?(weakSelf)
        }

    }
    
    func fetchUsersFromRecords(records: [CKRecord],completionBlock: (([CKRecord]) -> Void)? ,handleError: ((NSError) -> Void)? = nil) {
        var userRecordIDs = Array(Set(records.map { $0.creatorUserRecordID! }))
        let knownUserRecordNames = AppDelegate.Cache.Manager.knownUserRecordNames
        userRecordIDs = userRecordIDs.filter {
            if $0.recordName == CKOwnerDefaultName { return false }
            if knownUserRecordNames.contains( $0.recordName) { return false }
            return true
        }
        print("records count: \(records.count)")
        print("Users count: \(userRecordIDs.count)")
        guard userRecordIDs.count > 0 else {
            self.callBackBlock()
            return
        }
        
        self.loadingPage = true
        
        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)
        
        fetchUsersOperation.perRecordCompletionBlock = {
            (user, userRecordID, error) in
            guard error == nil else { return print(error!.localizedDescription)  }
            AppDelegate.Cache.Manager.cacheUser(user!)
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
            
            self.callBackBlock()
            
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(fetchUsersOperation)
    }
    

    
}



extension CKRecord {
    var createdBy: CKRecord? {
        return AppDelegate.Cache.Manager.userForUserRecordID(creatorUserRecordID!)
    }
}


