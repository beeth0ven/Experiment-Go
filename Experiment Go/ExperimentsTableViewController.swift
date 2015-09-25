//
//  ExperimentsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/23/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

class ExperimentsTableViewController: CloudKitTableViewController, CurrentUserHasChangeObserver {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startObserveCurrentUserHasChange()
    }
    deinit { stopObserveCurrentUserHasChange() }
    func updateUI() { self.tableView.updateVisibleCells() }

    override var refreshOperation: GetCKItemsOperation {
        let query = CKQuery(recordType: RecordType.Experiment.rawValue )
        return GetObjectsWithCreatorUserOperation(type: .Refresh(query))
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return GetObjectsWithCreatorUserOperation(type: .GetNextPage(cursor))
    }
    
    // MARK: - Segue
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
        

//        experiment.saveInBackground(
//            didFail: {
//                self.handleFail($0)
        //        items[indexPath.section].insert(experiment, atIndex: indexPath.row)
        //        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        
//            }
//        )
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