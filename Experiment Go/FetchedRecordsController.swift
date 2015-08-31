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

@objc protocol FetchedRecordsControllerDelegate: class {
    
    // Refresh Data Delegate
    optional func controllerWillRefreshData(controller: FetchedRecordsController)
    optional func controllerFailedToRefreshData(controller: FetchedRecordsController, error: NSError)
    optional func controllerDidRefreshData(controller: FetchedRecordsController)
    
    // Fetch Next Page Delegate
    optional func controllerWillFetchNextPage(controller: FetchedRecordsController)
    optional func controllerFailedToFetchNextPage(controller: FetchedRecordsController, error: NSError)
    optional func controllerDidFetchNextPage(controller: FetchedRecordsController)
    
    // Content Change Delegate
    optional func controllerWillChangeContent(controller: FetchedRecordsController)
    
    optional func controller(controller: FetchedRecordsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?)
    
    optional func controller(controller: FetchedRecordsController,
        didChangeSections sections: NSIndexSet,
        forChangeType type: NSFetchedResultsChangeType)
    
    optional func controllerDidChangeContent(controller: FetchedRecordsController)
    
    // Add New Records Delegate

    optional func controllerWillAddRecords(controller: FetchedRecordsController)
    optional func controllerFailedToAddRecords(controller: FetchedRecordsController, records: [CKRecord], error: NSError)
    optional func controllerDidAddRecords(controller: FetchedRecordsController)

}

class FetchedRecordsController: NSObject {
    
    var fetchedQuery: CKQuery
    var recordsPerPage: Int
    var includeCreatorUser: Bool
    
    weak var delegate: FetchedRecordsControllerDelegate?

    var fetchedRecords = [[CKRecord]]()

    init(fetchedQuery: CKQuery, recordsPerPage: Int, includeCreatorUser: Bool) {
        self.fetchedQuery = fetchedQuery
        self.recordsPerPage = recordsPerPage
        self.includeCreatorUser = includeCreatorUser
    }
    
    var moreComing: Bool {
        return nextPageToQuery != nil ? true : false
    }
    
    private var loadingStates: RecordsFetchType?  {
        didSet {
            if loadingStates != nil {
//                print("Loading Page.")
            } else {
//                print("Stop loading Page.")
            }
        }
    }
    
    
    // MARK: - Refresh data from cloud
    
    func refreshData() {
        guard shoudRefreshData else { return }
        
        loadingStates = .RefreshData
        self.delegate?.controllerWillRefreshData?(self)
        
        fetchedRecords = [[CKRecord]]()
        currentPageRecords = [CKRecord]()
        
        let queryOperation =  CKQueryOperation(query: fetchedQuery)
        queryOperation.resultsLimit = recordsPerPage
        
        queryOperation.recordFetchedBlock = recordFetchedBlock
        queryOperation.queryCompletionBlock = recordsFetchedBlock
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(queryOperation)
        
    }
    
    var shoudRefreshData: Bool {
        guard loadingStates == nil  else {
//            print("Shoudn't Refresh Data. A querry is in process.") ; 
            return false }
        return true
    }
    
    private var currentPageRecords = [CKRecord]()

    // MARK: - Fetch next page from cloud

    func fetchNextPage() {
        guard shouldLoadNextPage else { return }
        
        loadingStates = .FetchNextPage
        self.delegate?.controllerWillFetchNextPage?(self)

        currentPageRecords = [CKRecord]()
        
        let queryOperation = nextPageToQuery!
        queryOperation.resultsLimit = recordsPerPage
        queryOperation.recordFetchedBlock = recordFetchedBlock
        queryOperation.queryCompletionBlock = recordsFetchedBlock
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(queryOperation)
    }
    
    var shouldLoadNextPage: Bool {
        guard moreComing  else { return false  }
        guard loadingStates == nil else {
//            print("A querry is in process.") ;
            return false  }
        return true
    }
    
    private var nextPageToQuery: CKQueryOperation? {
        if let lastQueryCursor = lastQueryCursor {
            return CKQueryOperation(cursor: lastQueryCursor)
        } else {
            return nil
        }
    }

    lazy var recordFetchedBlock: (CKRecord) -> Void = {
        [weak self] (experiment) in
        guard let weakSelf = self else { return }
        weakSelf.currentPageRecords.append(experiment)
    }

    private var currentQueryCursor: CKQueryCursor?
    
    lazy var recordsFetchedBlock:  (CKQueryCursor?, NSError?) -> Void = {
        [weak self] (cursor, error) in
        guard let weakSelf = self else { return }
        guard error == nil else { weakSelf.handleError(error!) ; return }
        weakSelf.currentQueryCursor = cursor
        guard weakSelf.includeCreatorUser == false else { weakSelf.fetchUsersFromRecords(weakSelf.currentPageRecords)  ; return }
        weakSelf.callBackBlock()
        
    }
    
    func handleError(error: NSError) {
        dispatch_async(dispatch_get_main_queue()) {
            guard self.loadingStates != nil else { abort() }
            if case .RefreshData = self.loadingStates! {
                self.delegate?.controllerFailedToRefreshData?(self, error: error)
            } else {
                self.delegate?.controllerFailedToFetchNextPage?(self, error: error)
            }
            self.loadingStates = nil
        }
    }
    
    private var lastQueryCursor: CKQueryCursor?
    
    func callBackBlock() {
        dispatch_async(dispatch_get_main_queue()) {
            guard self.loadingStates != nil else { abort() }
            self.lastQueryCursor = self.currentQueryCursor
            self.delegate?.controllerWillChangeContent?(self)
            self.fetchedRecords.append(self.currentPageRecords)
            self.delegate?.controller?(self, didChangeSections: NSIndexSet(index: self.fetchedRecords.endIndex - 1) , forChangeType: .Insert)
            self.delegate?.controllerDidChangeContent?(self)
            
            if case .RefreshData = self.loadingStates! {
                self.delegate?.controllerDidRefreshData?(self)
            } else {
                self.delegate?.controllerDidFetchNextPage?(self)
            }
            
            self.loadingStates = nil
        }

    }
    
    // MARK: - Fetch users from cloud
    
    func fetchUsersFromRecords(records: [CKRecord]) {
        var userRecordIDs = Array(Set(records.map { $0.creatorUserRecordID! }))
        let knownUserRecordNames = AppDelegate.Cache.Manager.knownUserRecordNames
        userRecordIDs = userRecordIDs.filter {
            if $0.recordName == CKOwnerDefaultName { return false }
            if knownUserRecordNames.contains( $0.recordName) { return false }
            return true
        }
        guard userRecordIDs.count > 0 else { self.callBackBlock() ; return }

        let fetchUsersOperation = CKFetchRecordsOperation(recordIDs: userRecordIDs)

        fetchUsersOperation.perRecordCompletionBlock = userFetchedBlock
        fetchUsersOperation.fetchRecordsCompletionBlock = usersFetchedBlock
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(fetchUsersOperation)
        
    }
    
    lazy var userFetchedBlock: (CKRecord?, CKRecordID?, NSError?) -> Void = {
        (user, userRecordID, error) in
        guard error == nil else { return print(error!.localizedDescription)  }
        AppDelegate.Cache.Manager.cacheUser(user!)
    }

    
    lazy var usersFetchedBlock: ([CKRecordID : CKRecord]?, NSError?) -> Void = {
        [weak self] (_, error) in
        guard let weakSelf = self else { return }
        guard error == nil else {  weakSelf.handleError(error!) ; return }
        weakSelf.callBackBlock()
    }

    private enum RecordsFetchType {
        case RefreshData
        case FetchNextPage
    }
    
    // MARK: - Fetch users from cloud
    
    func addNewRecords(records: [CKRecord]) {
        
        delegate?.controllerWillAddRecords?(self)
        
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        modifyRecordsOperation.modifyRecordsCompletionBlock = {
            (_, _, error)  in
            dispatch_async(dispatch_get_main_queue()) {
                guard error == nil else { self.delegate?.controllerFailedToAddRecords?(self, records: records, error: error!) ; return  }
                self.delegate?.controllerWillChangeContent?(self)
                self.fetchedRecords.insert(records, atIndex: 0)
                self.delegate?.controller?(self, didChangeSections: NSIndexSet(index: 0) , forChangeType: .Insert)
                self.delegate?.controllerDidChangeContent?(self)
                
                self.delegate?.controllerDidAddRecords?(self)
            }
            
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(modifyRecordsOperation)

    }
    
}



extension CKRecord {
    var createdBy: CKRecord? {
        return AppDelegate.Cache.Manager.userForUserRecordID(creatorUserRecordID!)
    }
}


