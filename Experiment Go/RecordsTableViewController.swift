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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(false)
        showOrHideToolBarIfNeeded()

    }
    
    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // MARK: - Segue
    @IBInspectable
    var showRecordModelly: Bool = false
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == SegueID.ShowRecord.rawValue && showRecordModelly {
            performSegueWithIdentifier(SegueID.ShowRecordModelly.rawValue, sender: sender)
            return false
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
            
        case .ShowRecordModelly:
            guard
                let cell = sender as? RecordTableViewCell,
                let rdvc = segue.destinationViewController.contentViewController as? RecordDetailViewController
                else { return }
            rdvc.record = cell.record
            
        }
    }
    
    func addNewRecord() -> CKRecord {
        let result = CKRecord(recordType: recordType)
        switch recordType {
        case ExperimentKey.RecordType:
            result[ExperimentKey.Title] = "翡翠👌 石头 过d。"
        default: break
        }
        return result
    }
    
    private enum SegueID: String {
        case AddRecord
        case ShowRecord
        case ShowRecordModelly
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


