//
//  MasterViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit


class MasterViewController: UITableViewController {
    struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 87
        static let ExperimentCellReuseIdentifier = "ExperimentCell"
        static let ShowExperimentDetailSegueIdentifier = "showDetail"
    }
    
    var masterCloudManager = MasterCloudManager()
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        refresh()
        startObserveNotification()
    }
    
    deinit {
        stopObserveNotification()
    }
 
    // MARK: - Update UI
    
    func refresh() {
        refreshControl?.beginRefreshing()
        refresh(refreshControl)
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        
        masterCloudManager.refreshData({
            (experiments) in
            self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
            self.refreshControl?.endRefreshing()
            self.fetchUsersFrom(experiments)

            }, handleError: defaultHandleError)
        
        let indexSet = NSIndexSet(indexesInRange: NSMakeRange(0, tableView.numberOfSections))
        tableView.deleteSections(indexSet, withRowAnimation: .Fade)
    }
    
    private func fetchUsersFrom(experiments: [CKRecord]) {
        
        masterCloudManager.fetchUsersFrom(experiments, completionBlock: {
            (userRecords) in
            let userRecordIDs: [CKRecordID] = userRecords.map { $0.recordID }
            for (section, experiments) in self.masterCloudManager.experiments.enumerate() {
                for (row, experiment) in experiments.enumerate() {
                    let userRecordID = experiment.valueForKey(RecordKey.CreatorUserRecordID) as! CKRecordID
                    if userRecordIDs.contains(userRecordID) {
                        let indexPath = NSIndexPath(forRow: row, inSection: section)
                        guard let visibleCell = self.tableView.cellForRowAtIndexPath(indexPath) else { return }
                        self.configureCell(visibleCell, atIndexPath: indexPath)
                    }
                }
            }
        }, handleError: defaultHandleError)
    }
    

    
    @objc func updateUserRelatedUI() {
        for (section, experiments) in self.masterCloudManager.experiments.enumerate() {
            for (row, experiment) in experiments.enumerate() {
                let userRecordID = experiment.valueForKey(RecordKey.CreatorUserRecordID) as! CKRecordID
                if userRecordID.recordName == CKOwnerDefaultName {
                    let indexPath = NSIndexPath(forRow: row, inSection: section)
                    guard let visibleCell = self.tableView.cellForRowAtIndexPath(indexPath) else { return }
                    self.configureCell(visibleCell, atIndexPath: indexPath)
                }
            }
            
        }
    }
    
    let defaultHandleError: ((NSError) -> Void) = { (error) in
        print(error.localizedDescription) ; abort()
    }
    
    // MARK: - Key Value Observe

    func startObserveNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateUserRelatedUI",
            name: CloudManager.Notification.CurrentUserDidChange,
            object: nil)
    }
    
    func stopObserveNotification() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return masterCloudManager.experiments.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return masterCloudManager.experiments[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.ExperimentCellReuseIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let experimentCell = cell as? ExperimentTableViewCell else { abort() }
        let experiment = masterCloudManager.experiments[indexPath.section][indexPath.row]
        experimentCell.authorProfileImage = nil
        experimentCell.titleLabel.text = experiment.valueForKey(ExperimentKey.Title) as? String
        experimentCell.creationDateLabel.text = NSDateFormatter.smartStringFormDate(experiment.valueForKey(RecordKey.CreationDate) as! NSDate)
        guard let user =  masterCloudManager.userForExperiment(experiment) else { return }
        guard let imageData = (user.valueForKey(UserKey.ProfileImageAsset) as? CKAsset)?.data else { return }
        experimentCell.authorProfileImage = UIImage(data: imageData)
        
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
            let experiment = masterCloudManager.experiments[indexPath.section][indexPath.row]
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
                    self.masterCloudManager.experiments.insert([experiment!], atIndex: 0)
                    self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
                    self.refreshControl?.endRefreshing()
                }
            }

        }
    }
    

}

extension CKQueryOperation {
    convenience init(recordType: String) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.CreationDate, ascending: false)]
        self.init(query: query)
    }
}



