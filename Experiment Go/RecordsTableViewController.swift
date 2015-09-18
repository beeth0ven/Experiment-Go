//
//  RecordsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit
import CoreData


class RecordsTableViewController: CloudKitTableViewController {
    
    
    
    @IBOutlet var addRecordBarButtonItem: UIBarButtonItem!
    
    
    @IBInspectable
    var preferedBarSeparatorHidden: Bool = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(preferedBarSeparatorHidden)
        showOrHideToolBarIfNeeded()

    }
    
    
    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Segue
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == SegueID.AddRecord.rawValue {
            if hasCloudWritePermision != true {
                presentWelcomeToCloudTVC { self.performSegueWithIdentifier(identifier, sender: sender) }
                return false
            }
        }
        
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .AddRecord:
            guard let rdvc = segue.destinationViewController.contentViewController as? RecordDetailViewController else { return }
            let record = addNewRecord()
            rdvc.record = record
            rdvc.recordInserted = true
            
        case .ShowRecord:
            guard
                let cell = sender as? RecordTableViewCell,
                let rdvc = segue.destinationViewController.contentViewController as? RecordDetailViewController
                else { return }
            rdvc.record = cell.record
            
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController,
                let cell = UITableViewCell.cellContainsSubView(sender as! UIButton) as? RecordTableViewCell else { return }
            udvc.user = cell.record?.createdBy
            
        }
    }
    
    func addNewRecord() -> CKRecord {
        guard let recordType = RecordType(rawValue: recordType) else { abort() }
        switch recordType {
        case .Experiment:
            let experiment = CKRecord(recordType: recordType.rawValue)
            experiment[ExperimentKey.Title] = "翡翠👌 石头 过"
            return experiment
        case .Review:
            guard let nav = navigationController else { abort() }
            guard let rdvc = nav.viewControllers[nav.viewControllers.indexOf(self)! - 1] as? RecordDetailViewController else { abort() }
            return CKRecord(reviewToExperiment: rdvc.record!)
        default:
            return CKRecord(recordType: recordType.rawValue)
        }
    }
    
    private enum SegueID: String {
        case AddRecord
        case ShowRecord
        case ShowUserDetail
    }
    
}

extension RecordsTableViewController {
    // MARK: - Unwind Segue
    
    @IBAction func addRecordDidClickSave(segue: UIStoryboardSegue) {
        guard let rdvc = segue.sourceViewController as? RecordDetailViewController else { abort() }
        fetchedRecordsController.addNewRecords([rdvc.record!])
        if segue.sourceViewController.presentingViewController == self.splitViewController {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func controllerWillAddRecords(controller: FetchedRecordsController) {
        navigationItem.rightBarButtonItem = activityBarButtonItem
    }
    
    func controllerFailedToAddRecords(controller: FetchedRecordsController, records: [CKRecord], error: NSError) {
        print(error.localizedDescription) ; abort()
    }
    
    func controllerDidAddRecords(controller: FetchedRecordsController) {
        navigationItem.rightBarButtonItem = addRecordBarButtonItem
    }
    
    override func canPerformUnwindSegueAction(action: Selector, fromViewController: UIViewController, withSender sender: AnyObject) -> Bool {
        print ("topViewController title: \(navigationController?.topViewController?.title)")
        let presentingVC = fromViewController.presentingViewController
        if presentingVC == splitViewController { return true }
        if presentingVC == navigationController && navigationController?.topViewController == self { return true }
        if presentingVC == self { return true }
        return false
    }
    
}


