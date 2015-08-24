//
//  MasterViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit


class MasterViewController: CloudKitTableViewController {
    
    // MARK: - Method to override from super class

    // Required
    
    override func configureCell(cell: UITableViewCell, forRecord record: CKRecord) {
        let experiment = record
        guard let experimentCell = cell as? ExperimentTableViewCell else { abort() }
        experimentCell.authorProfileImage = nil
        experimentCell.titleLabel.text = experiment[ExperimentKey.Title] as? String
        experimentCell.creationDateLabel.text = NSDateFormatter.smartStringFormDate(experiment[RecordKey.CreationDate] as! NSDate)
        guard let user =  experiment.createdBy else { return }
        guard let imageData = (user[UserKey.ProfileImageAsset] as? CKAsset)?.data else { return }
        experimentCell.authorProfileImage = UIImage(data: imageData)
        
    }
    
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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

extension MasterViewController {
    // MARK: - Unwind Segue 
    @IBAction func addExperimentDidCancel(segue: UIStoryboardSegue) {
        
    }

    @IBAction func addExperimentDidPost(segue: UIStoryboardSegue) {
        guard let edvc = segue.sourceViewController as? ExperimentDetailViewController else { abort() }
        dismissViewControllerAnimated(true) {
            self.refreshControl?.beginRefreshing()
            self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            self.publicCloudDatabase.saveRecord(edvc.experiment!) { (experiment, error) -> Void in
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




