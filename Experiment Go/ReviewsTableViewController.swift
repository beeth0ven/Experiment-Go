//
//  ReviewsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class ReviewsTableViewController: CloudKitTableViewController {
    
    var reviewTo: CKExperiment?
    
    override var refreshOperation: GetCKItemsOperation {
        return GetReviewsOperation(reviewTo: reviewTo!)
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return GetReviewsOperation(type: .GetNextPage(cursor))
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddReview:
            guard let rvc = segue.destinationViewController.contentViewController as? ReviewViewController else { return }
            let review = CKLink(reviewTo: reviewTo!)
            rvc.review = review
            rvc.done = saveReview
        
        }
    }
    
    func saveReview(review: CKLink) {
        
        items.insert([review], atIndex: 0)
        tableView.insertSectionAtIndex(0)
        review.saveInBackground(
            didFail: {
                self.handleFail($0)
                let index = self.items.indexOf { $0 == [review] }!
                self.items.removeAtIndex(index)
                self.tableView.deleteSectionAtIndex(index)
            }
        )
    }
    
    private enum SegueID: String {
        case AddReview
    }
}