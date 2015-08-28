//
//  CloudKitTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/24/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit
import CoreData

@IBDesignable

class CloudKitTableViewController: UITableViewController {

    // MARK: - Public
    
    // Require to be setted from storyboard
    @IBInspectable
    var recordType: String = ExperimentKey.RecordType
    
    @IBInspectable
    var cellReusableIdentifier: String = ""

    // Optional to be setted from storyboard
    
    @IBInspectable
    var sortKey: String = "creationDate"
    
    @IBInspectable
    var sortAscending: Bool = false
    
    @IBInspectable
    var recordsPerPage: Int = 10

    @IBInspectable
    var includeCreatorUser: Bool = true
    
    @IBInspectable
    var estimatedRowHeight: CGFloat = 80

    
    // Optional to be override for subclass
    
    func queryPredicate() -> NSPredicate {
        return NSPredicate(value: true)
    }
    
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
        startObserveIfNeeded()
    }
    
    deinit {
       stopObserveIfNeeded()
    }
   
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(false)
        navigationController?.showOrHideToolBarIfNeeded()
    }
    
    // MARK: - Key Value Observe
    
    var uno: NSObjectProtocol?
    
    private func startObserveIfNeeded() {
        guard includeCreatorUser else { return }
        uno =
            NSNotificationCenter.defaultCenter().addObserverForName(CurrentUserDidChangeNotification,
                object: nil,
                queue: NSOperationQueue.mainQueue(),
                usingBlock: {
                    (_) in
                    self.updateVisibleCells()
            })
    }
    
    private func stopObserveIfNeeded() {
        guard uno != nil else { return }
        NSNotificationCenter.defaultCenter().removeObserver(uno!)
    }
    
    // MARK: - @IBAction
    
    func refresh() {
        refresh(refreshControl)
    }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        guard fetchedRecordController.shoudRefreshData else { refreshControl?.endRefreshing() ; return  }
        fetchedRecordController.refreshData(recordsFetchedBlock, handleError: defaultHandleError)
        refreshControl?.beginRefreshing()
        if refreshControl != nil { tableView.tableFooterView = UIView() }

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
    }
    
    lazy var defaultHandleError: ((NSError) -> Void) = {
        (error) in
        print(error.localizedDescription)
//        abort()
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
        guard let recordCell = cell as? RecordTableViewCell else { return }
        recordCell.record = record
    }
    
    
    
    // MARK: - Scroll View
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard fetchedRecordController.moreComing else { return print("have fetched all result.") }
        let tableBottomHeight = scrollView.contentOffset.y + scrollView.bounds.height
        let contentBottomHeight = scrollView.contentSize.height
        if contentBottomHeight - tableBottomHeight < scrollView.bounds.height/2 {
//            print("delta height: \(contentBottomHeight - tableBottomHeight - scrollView.bounds.height/2)")
            loadNextPage()
        }
    }

    
    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func queryForTable() -> CKQuery {
        let query = CKQuery(recordType: recordType, predicate: queryPredicate())
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
        _fetchedRecordController!.delegate = self
        return _fetchedRecordController!
    }
    
    var _fetchedRecordController: FetchedRecordController?
}

extension CloudKitTableViewController: FetchedRecordControllerDelegate {
    
    func controllerWillChangeContent(controller: FetchedRecordController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: FetchedRecordController, didChangeSections sections: NSIndexSet, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(sections, withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(sections, withRowAnimation: .Fade)
        default: break
        }
    }
    
    
    func controllerDidChangeContent(controller: FetchedRecordController) {
        tableView.endUpdates()
        refreshControl?.endRefreshing()
        tableView.tableFooterView = fetchedRecordController.moreComing ? loadPageActivityView : UIView()
    }
}





