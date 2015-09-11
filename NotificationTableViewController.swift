//
//  NotificationTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/6/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class NotificationTableViewController: UITableViewController {
    
    // MARK: - Cloud Stack

    private var notificationRecords: [[CKRecord]] {
        get { return AppDelegate.Cloud.Manager.notificationRecords }
        set { AppDelegate.Cloud.Manager.notificationRecords = newValue }
    }
    
    private var currentPageNotificationRecordIDs = [CKRecordID]()
    private var currentServerChangeToken: CKServerChangeToken?
    private var moreComing = false
    
    func fetchNextPage() {
        refreshControl?.beginRefreshing()
        tableView.scrollRectToVisible(CGRectMake(0, 0, 0, 0), animated: true)
        refresh(refreshControl!)
    }
    
    @IBAction func refresh(sender: UIRefreshControl) {
        currentPageNotificationRecordIDs.removeAll()
        
        
//        print("previousChangeToken: \(previousChangeToken)")
//        let fetchNotificationChangesOp = CKFetchNotificationChangesOperation(previousServerChangeToken: previousChangeToken)
//        fetchNotificationChangesOp.resultsLimit = 30
//        
//        fetchNotificationChangesOp.fetchNotificationChangesCompletionBlock = {
//            [unowned fetchNotificationChangesOp] (taken, error) in
//            self.previousChangeToken = taken
//            if fetchNotificationChangesOp.moreComing { self.refresh(self.refreshControl!) }
//        }
//        
//        fetchNotificationChangesOp.start()
        
        print("previousChangeToken: \(previousChangeToken)")
        let fetchNotificationChangesOp = CKFetchNotificationChangesOperation(previousServerChangeToken: previousChangeToken)
        fetchNotificationChangesOp.resultsLimit = 30
        fetchNotificationChangesOp.notificationChangedBlock = { self.currentPageNotificationRecordIDs.append(($0 as! CKQueryNotification).recordID! ) }
        
        fetchNotificationChangesOp.fetchNotificationChangesCompletionBlock = {
            [unowned fetchNotificationChangesOp] (taken, error) in
            guard error == nil else { abort() }
            self.currentServerChangeToken = taken
            self.moreComing = fetchNotificationChangesOp.moreComing
            self.fetchNotificationRecordsFrom(self.currentPageNotificationRecordIDs)
        }
        
        fetchNotificationChangesOp.start()

    }
    
    private var currentPageNotificationRecords = [CKRecord]()
    
    
    func fetchNotificationRecordsFrom(recordIDs: [CKRecordID]) {
        guard recordIDs.count > 0 else { refreshControl?.endRefreshing() ; return }
        currentPageNotificationRecords.removeAll() 
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
        fetchRecordsOperation.perRecordCompletionBlock = {
            (record, recordID, error) in
            guard error == nil else { return print(error!.localizedDescription)  }
            self.currentPageNotificationRecords.append(record!)
        }
        
        fetchRecordsOperation.fetchRecordsCompletionBlock = {
            (_, error) in
            guard error == nil else { abort() }
            self.notificationRecords.insert(self.currentPageNotificationRecords, atIndex: 0)
            self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
            self.refreshControl?.endRefreshing()
            self.previousChangeToken = self.currentServerChangeToken
            if self.moreComing { self.fetchNextPage() }

        }
        
        AppDelegate.Cloud.Manager.publicCloudDatabase.addOperation(fetchRecordsOperation)
    }
    
    
    
    private var previousChangeToken: CKServerChangeToken?  {
        get { return AppDelegate.Cloud.Manager.previousChangeToken }
        set { AppDelegate.Cloud.Manager.previousChangeToken = newValue }
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        fetchNextPage()
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return notificationRecords.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationRecords[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let recordCell = cell as? RecordTableViewCell else { return }
        let record = notificationRecords[indexPath.section][indexPath.row]
        recordCell.record = record
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let notificationCellType = notificationCellTypeAtIndexPath(indexPath)
        switch notificationCellType {
        case .UserReviewExperiment:
            performSegueWithIdentifier(SegueID.ShowReviews.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        case .UserLikeExperiment:
            performSegueWithIdentifier(SegueID.ShowFans.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        case .UserFollowUser:
            performSegueWithIdentifier(SegueID.ShowFollower.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))

        }
        
    }
    
    private func notificationCellTypeAtIndexPath(indexPath: NSIndexPath) -> RecordNotificationType {
        let record = notificationRecords[indexPath.section][indexPath.row]
        let recordType = RecordType(rawValue: record.recordType)!
        if case .Link = recordType {
            let linkType = LinkType(rawValue: record[LinkKey.LinkType] as! String)!
            switch linkType {
            case .UserLikeExperiment:
                 return .UserLikeExperiment
            case .UserFollowUser:
                return .UserFollowUser
            }
        }
        return .UserReviewExperiment
    }
    
    private enum RecordNotificationType {
        case UserReviewExperiment
        case UserLikeExperiment
        case UserFollowUser
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        let record = (sender as! RecordTableViewCell).record!
        switch segueID {
        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate = NSPredicate(format: "%K = %@", ReviewKey.To, record[ReviewKey.To] as! CKReference)

            
        case .ShowFans:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserLikeExperiment.rawValue)
            let toPredicate = NSPredicate(format: "%K = %@", LinkKey.To, record[ReviewKey.To] as! CKReference)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [toPredicate, typePredicate])

         
        case .ShowFollower:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserFollowUser.rawValue)
            let userPredicate = NSPredicate(format: "%K = %@", LinkKey.To, record[ReviewKey.To] as! CKReference)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
            rtvc.title = "Follower"
        }
    }
    
    private enum SegueID: String {
        case ShowReviews
        case ShowFans
        case ShowFollower
    }
    
}


