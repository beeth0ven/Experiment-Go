//
//  ReviewsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

class ReviewsTableViewController: CloudKitTableViewController {
    var reviewTo: CKRecord?
    
    override func queryPredicate() -> NSPredicate {
        guard let reviewTo = reviewTo else { return super.queryPredicate() }
        return NSPredicate(format: "%K = %@", ReviewKey.ReviewTo, reviewTo)
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddReview:
            guard let rvc = segue.destinationViewController.contentViewController as? ReviewViewController else { return }
            let review = CKRecord(reviewTo: reviewTo!)
            rvc.review = review
        }
    }
    
    private enum SegueID: String {
        case AddReview
    }
    
}

extension CKRecord {
    convenience init(reviewTo: CKRecord) {
        self.init(recordType: ReviewKey.RecordType)
        self[ReviewKey.ReviewTo] = CKReference(record: reviewTo, action: .DeleteSelf)
    }
}


extension ReviewsTableViewController {
    // MARK: - Unwind Segue
    @IBAction func addReviewDidClickCancel(segue: UIStoryboardSegue) {
    }
    
    @IBAction func addReviewDidClickSave(segue: UIStoryboardSegue) {
        guard let rvc = segue.sourceViewController as? ReviewViewController else { abort() }
        self.refreshControl?.beginRefreshing()
        self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
        AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(rvc.review!) { (review, error) in
            guard error == nil else { print(error!.localizedDescription) ; abort() }
            dispatch_async(dispatch_get_main_queue()) {
                self.fetchedRecordController.fetchedRecords.insert([review!], atIndex: 0)
                self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
                self.refreshControl?.endRefreshing()
            }
            
        }
    }
    
    
}
