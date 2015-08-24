//
//  CloudKitTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/24/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

@IBDesignable

class CloudKitTableViewController: UITableViewController {

    // MARK: - Var set from storyboard or Method to override
    
    // Require
    @IBInspectable
    var queryRecordType: String = ExperimentKey.RecordType
    
    @IBInspectable
    var cellReusableIdentifier: String = ""

    func configureCell(cell: UITableViewCell, forRecord record: CKRecord) {
        
    }
    
    // Optional
    
    @IBInspectable
    var sortKey: String = "creationDate"
    
    @IBInspectable
    var sortAscending: Bool = false
    
    @IBInspectable
    var recordsPerPage: Int = 5

    @IBInspectable
    var includeCreatorUser: Bool = true
    
    
    func queryPredicate() -> NSPredicate {
        return NSPredicate(value: true)
    }

    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
    }
    
    
    // MARK: - @IBAction
    
    func refresh() {
        refreshControl?.beginRefreshing()
        refresh(refreshControl)
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        guard fetchedRecordController.shoudRefreshData else { refreshControl?.endRefreshing() ; return  }
        tableView.tableFooterView = UIView()
        fetchedRecordController.refreshData(recordsFetchedBlock, handleError: defaultHandleError)
        let indexSet = NSIndexSet(indexesInRange: NSMakeRange(0, tableView.numberOfSections))
        tableView.deleteSections(indexSet, withRowAnimation: .Fade)
    }
    
    func loadNextPage() {
        fetchedRecordController.fetchNextPage(recordsFetchedBlock)
    }
    
    // MARK: - Update UI
    @IBOutlet var loadPageActivityView: UIView!

    func updateVisibleCells() {
        for cell in self.tableView.visibleCells {
            self.configureCell(cell, atIndexPath: self.tableView.indexPathForCell(cell)!)
        }
    }
    

    
    // MARK: - Block
    
    lazy var recordsFetchedBlock: ([CKRecord]) -> Void = {
        [weak self] (experiments) in
        guard let weakSelf = self else { return }
        weakSelf.tableView.insertSections(NSIndexSet(index: weakSelf.tableView.numberOfSections), withRowAnimation: .Fade)
        weakSelf.refreshControl?.endRefreshing()
        weakSelf.tableView.tableFooterView = weakSelf.fetchedRecordController.moreComing ? weakSelf.loadPageActivityView : UIView()
    }
    
    lazy var defaultHandleError: ((NSError) -> Void) = {
        (error) in
        print(error.localizedDescription) ; abort()
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedRecordController.fetchedRecords.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedRecordController.fetchedRecords[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let record = fetchedRecordController.fetchedRecords[indexPath.section][indexPath.row]
        configureCell(cell, forRecord: record)
    }
    
    
    
    // MARK: - Scroll View
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard fetchedRecordController.moreComing else { return print("have fetched all result.") }
        let tableBottomHeight = scrollView.contentOffset.y + scrollView.bounds.height
        let contentBottomHeight = scrollView.contentSize.height
        if contentBottomHeight - tableBottomHeight < scrollView.bounds.height/2 {
            print("delta height: \(contentBottomHeight - tableBottomHeight - scrollView.bounds.height/2)")
            loadNextPage()
        }
    }

    
    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func queryForTable() -> CKQuery {
        let query = CKQuery(recordType: queryRecordType, predicate: queryPredicate())
        query.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: sortAscending)]
        return query
    }
    
    var fetchedRecordController: FetchedRecordController {
        if _fetchedRecordController != nil { return _fetchedRecordController! }
        _fetchedRecordController = FetchedRecordController(
            fetchedQuery: queryForTable(),
            recordsPerPage: recordsPerPage,
            includeCreatorUser: includeCreatorUser
        )
        return _fetchedRecordController!
    }
    
    
    
    var _fetchedRecordController: FetchedRecordController?
}