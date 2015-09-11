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
    
    var passCreatorUser: Bool
    
    var fetchType: FetchType
    
    enum FetchType: String {
        case Single
        case IncludeCreatorUser
        case LinkIncludeDestination
        case LinkIncludeDestinationAndDestinationCreatorUser
    }
    
    weak var delegate: FetchedRecordsControllerDelegate?

    var fetchedRecords = [[CKRecord]]()

    init(fetchedQuery: CKQuery, recordsPerPage: Int, passCreatorUser: Bool, fetchType: FetchType) {
        self.fetchedQuery = fetchedQuery
        self.recordsPerPage = recordsPerPage
        self.passCreatorUser = passCreatorUser
        self.fetchType = fetchType
    }
    
    var moreComing: Bool {
        return nextPageToQuery != nil ? true : false
    }
    
    private var loadingStates: RecordsFetchType?
    
    
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
        switch weakSelf.fetchType {
        case .Single:
            weakSelf.callBackBlock()
        case .IncludeCreatorUser:
             weakSelf.fetchUsersFromRecords(weakSelf.currentPageRecords)
        case .LinkIncludeDestination:
            weakSelf.fetchDestinationFromLinks(weakSelf.currentPageRecords)
        case .LinkIncludeDestinationAndDestinationCreatorUser:
            weakSelf.fetchDestinationFromLinks(weakSelf.currentPageRecords)
        }
        
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
            switch self.fetchType {
            case .Single:
                self.fetchedRecords.append(self.currentPageRecords)
            case .IncludeCreatorUser:
                self.passCreatorUser == false ?
                    self.fetchedRecords.append(self.currentPageRecords):
                    self.fetchedRecords.append(self.currentPageRecords.map { $0.createdBy! })
            case .LinkIncludeDestination:
                self.fetchedRecords.append(self.currentPageRecords.map { self.currentFetchedDestinationRecords![$0.linkToRecordID!]! })
                
            case .LinkIncludeDestinationAndDestinationCreatorUser:
                self.passCreatorUser == false ?
                    self.fetchedRecords.append(self.currentPageRecords.map { self.currentFetchedDestinationRecords![$0.linkToRecordID!]! })  :
                    self.fetchedRecords.append(self.currentPageRecords.map { self.currentFetchedDestinationRecords![$0.linkToRecordID!]!.createdBy! })
            }
            
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
    
    
    // MARK: - Fetch linked record from cloud
    
    func fetchDestinationFromLinks(links: [CKRecord]) {
        let linkRecordIDs = Array(Set(links.map { $0.linkToRecordID! }))
        guard linkRecordIDs.count > 0 else { self.callBackBlock() ; return }
        let fetchDestinationRecordsOperation = CKFetchRecordsOperation(recordIDs: linkRecordIDs)
        fetchDestinationRecordsOperation.fetchRecordsCompletionBlock = destinationRecordsFetchedBlock
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(fetchDestinationRecordsOperation)
    }
    
    lazy var destinationRecordsFetchedBlock: ([CKRecordID : CKRecord]?, NSError?) -> Void = {
        [weak self] (destinationRecordsByRecordID, error) in
        guard let weakSelf = self else { return }
        guard error == nil else {  weakSelf.handleError(error!) ; return }
        weakSelf.currentFetchedDestinationRecords = destinationRecordsByRecordID
        switch weakSelf.fetchType {
        case .LinkIncludeDestination:
            weakSelf.callBackBlock()
        case .LinkIncludeDestinationAndDestinationCreatorUser:
            weakSelf.fetchUsersFromRecords(weakSelf.currentPageRecords.map { destinationRecordsByRecordID![$0.linkToRecordID!]! })
        default: abort()
        }
    }
    
    var currentFetchedDestinationRecords: [CKRecordID : CKRecord]?
    

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
                self.addSubscriptionsFromRecords(records)
                
            }
            
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(modifyRecordsOperation)

    }
    
    func addSubscriptionsFromRecords(records: [CKRecord]) {
        guard let subscriptions = records.reduce([], combine: { $1.subscriptionsToAdd }) else { return }
        guard subscriptions.count > 0 else { return }
//        for subscription in subscriptions {
//            AppDelegate.Cloud.Manager.publicCloudDatabase.saveSubscription(subscription) {
//                (subscription, error) in
//                guard error == nil else { print(error!.localizedDescription) ; return }
//                print("Subscriptions did save.")
//            }
//        }
//
//        
        let modifySubscriptionsOperation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        modifySubscriptionsOperation.modifySubscriptionsCompletionBlock = {
            (_, _, error) in
            guard error == nil else {
                let info = error!.userInfo
                let dic = info[CKPartialErrorsByItemIDKey] as! [String: NSError]
                for (_, perError) in dic{
                    print(perError.localizedDescription)
                }
                print(error!.localizedDescription) ; return
            }
            print("Subscriptions did save.")
        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(modifySubscriptionsOperation)
    }
    
}








