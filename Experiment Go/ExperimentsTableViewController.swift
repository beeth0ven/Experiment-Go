//
//  MasterViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit


class ExperimentsTableViewController: CloudKitTableViewController {
    
    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(SegueID.ShowExperiment.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddExperiment:
            guard let edvc = segue.destinationViewController.contentViewController as? ExperimentDetailViewController else { return }
            let experiment = CKRecord(recordType: ExperimentKey.RecordType)
            experiment[ExperimentKey.Title] = "Hallo 🐶 Kitty?"
            edvc.experiment = experiment
            edvc.experimentInserted = true
            
        case .ShowExperiment:
            guard
                let cell = sender as? UITableViewCell,
                let edvc = segue.destinationViewController.contentViewController as? ExperimentDetailViewController
                else { return }
            
            let indexPath = tableView.indexPathForCell(cell)!
            let experiment = fetchedRecordController.fetchedRecords[indexPath.section][indexPath.row]
            edvc.experiment = experiment
        }
    }

    private enum SegueID: String {
        case AddExperiment
        case ShowExperiment
    }
}

extension ExperimentsTableViewController {
    // MARK: - Unwind Segue 
    @IBAction func addExperimentDidClickCancel(segue: UIStoryboardSegue) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func addExperimentDidClickSave(segue: UIStoryboardSegue) {
        guard let edvc = segue.sourceViewController as? ExperimentDetailViewController else { abort() }
        dismissViewControllerAnimated(true) {
            self.refreshControl?.beginRefreshing()
            self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(edvc.experiment!) { (experiment, error) -> Void in
                guard error == nil else { print(error!.localizedDescription) ; abort() }
                dispatch_async(dispatch_get_main_queue()) {
                    self.fetchedRecordController.fetchedRecords.insert([experiment!], atIndex: 0)
                    self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
                    self.refreshControl?.endRefreshing()
                }
            }

        }
    }
    

}




