//
//  ExperimentsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/23/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

class ExperimentsTableViewController: CloudKitTableViewController {
    
    var queryType: QueryType?
    
    override var refreshOperation: GetCKItemsOperation {
        switch queryType!{
        case .PostedBy(let user):
                return GetUserPostedExperimentsOperation(postedBy: user)
        case .LikedBy(let user):
            return GetUserLikedExperimentsOperation(likedBy: user)
        case .InteretedByCurrentUser:
            return GetCurrentUserInteretedExperimentsOperation()
        }
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        switch queryType!{
        case .PostedBy(_):
            return GetUserPostedExperimentsOperation(type: .GetNextPage(cursor))
        case .LikedBy(_):
            return GetUserLikedExperimentsOperation(type: .GetNextPage(cursor))
        case .InteretedByCurrentUser:
            return GetCurrentUserInteretedExperimentsOperation(type: .GetNextPage(cursor))
        }
    }
    
    enum QueryType {
        case PostedBy(CKUsers)
        case LikedBy(CKUsers)
        case InteretedByCurrentUser
    }
    
    // MARK: - Segue
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        guard let segueID = SegueID(rawValue: identifier) else { return true }
        guard case .AddExperiment = segueID else { return true }
        guard didAuthoriseElseRequest(didAuthorize: { self.performSegueWithIdentifier(identifier, sender: sender) }) else { return false }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddExperiment:
            guard let eadvc = segue.destinationViewController.contentViewController as? ExperimentAddedDVC else { return }
            let experiment = CKExperiment()
            eadvc.experiment = experiment
            eadvc.done = saveExperiment
            
        case .ShowExperiment:
            guard let edvc = segue.destinationViewController.contentViewController as? ExperimentDetailViewController else { return }
            let cell = sender as! ExperimentTableViewCell
            edvc.experiment = cell.experiment
            edvc.delete = deleteExperiment
            
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController,
            let cell = UITableViewCell.cellForView(sender as! UIButton) as? CKItemTableViewCell else { return }
            udvc.user = cell.item?.creatorUser
        }
    }
    
    func saveExperiment(experiment: CKExperiment) {
        
        items.insert([experiment], atIndex: 0)
        tableView.insertSectionAtIndex(0)
        experiment.saveInBackground(
            didFail: {
                self.handleFail($0)
                let index = self.items.indexOf { $0 == [experiment] }!
                self.items.removeAtIndex(index)
                self.tableView.deleteSectionAtIndex(index)
            }
        )
    }
    
    
    func deleteExperiment(experiment: CKExperiment) {
        let indexPath = indexPathForExperiment(experiment)!
        items[indexPath.section].removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        
        experiment.deleteInBackground(
            didFail: {
                self.handleFail($0)
                self.items[indexPath.section].insert(experiment, atIndex: indexPath.row)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        )
    }
    
    private func indexPathForExperiment(experiment: CKExperiment) -> NSIndexPath? {
        
        for (section, experiments) in items.enumerate() {
            for (row, aExperiment) in experiments.enumerate() {
                if aExperiment == experiment { return NSIndexPath(forRow: row, inSection: section) }
            }
        }
        return nil
    }
    
    private enum SegueID: String {
        case AddExperiment
        case ShowExperiment
        case ShowUserDetail
    }

}
extension UITableViewCell {
    class func cellForView(view: UIView) -> UITableViewCell? {
        var superView = view.superview
        while superView != nil {
            if let cell = superView as? UITableViewCell { return cell }
            superView = superView!.superview
        }
        return nil
    }
}

extension UITableView {
    func insertSectionAtIndex(index: Int) {
        insertSections(NSIndexSet(index: index), withRowAnimation: .Fade)
    }
    
    func deleteSectionAtIndex(index: Int) {
        deleteSections(NSIndexSet(index: index), withRowAnimation: .Fade)
    }
}