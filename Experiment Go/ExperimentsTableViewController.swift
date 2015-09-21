//
//  ExperimentsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import UIKit
import CloudKit

class ExperimentsTableViewController: UITableViewController {
    
    var experiments = [[CKExperiment]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
    }
    
    var lastQueryCursor: CKQueryCursor?
    
    private func refresh() {
        refreshControl?.beginRefreshing()
        refresh(refreshControl!)
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        
        experiments.removeAll()
        tableView.reloadData()

        let query = CKQuery(recordType: RecordType.Experiment.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: RecordKey.CreationDate, ascending: false)]
        
        let getExperimentsOperation = GetExperimentsOperation(type: .Query(query))
        getExperimentsOperation.didGet = {
            (experiments, cursor) in
            self.refreshControl?.endRefreshing()
            self.lastQueryCursor = cursor
            self.experiments.append(experiments)
            self.tableView.insertSections(NSIndexSet(index: self.experiments.count - 1), withRowAnimation: .Fade)
        }
        
        getExperimentsOperation.didFail = handleFail
        
        getExperimentsOperation.start()
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return experiments.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return experiments[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ExperimentCell", forIndexPath: indexPath) as! RecordTableViewCell
        cell.object = experiments[indexPath.section][indexPath.row]
        return cell
    }
    
}