//
//  FeedbackTVC.swift
//  Experiment Go
//
//  Created by luojie on 10/5/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import UIKit

class FeedbackTVC: UITableViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier(SegueID.AddReview.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddReview:
            guard let rvc = segue.destinationViewController.contentViewController as? ReviewViewController,
            let cell = sender as? UITableViewCell else { return }
            let review = CKLink(feedbackTitle: cell.title!)
            rvc.review = review
            rvc.title = "Feedback"
            rvc.done = {
                $0.saveInBackground(didFail: self.handleFail)
            }
            
        }
    }
    
    private enum SegueID: String {
        case AddReview
    }

}