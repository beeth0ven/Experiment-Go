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
    
    var sortKey: String = "creationDate"
    
    var sortAscending: Bool = false
    
//    @IBInspectable
    var recordsPerPage: Int = 20

//    @IBInspectable
    var includeCreatorUser: Bool = true
    
    @IBInspectable
    var estimatedRowHeight: CGFloat = 80

    var queryPredicate: NSPredicate = NSPredicate(value: true)
    
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        refresh()
        startObserveIfNeeded()
        configureBarButtons()
    }
    
    deinit {
       stopObserveIfNeeded()
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
        refreshControl?.endRefreshing()
        fetchedRecordsController.refreshData()
        tableView.reloadData()
    }
    
    // MARK: - Update UI

    
    func updateVisibleCells() {
        for cell in self.tableView.visibleCells {
            self.configureCell(cell, atIndexPath: self.tableView.indexPathForCell(cell)!)
        }
    }
    
    func configureTableView() {
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.tableFooterView = UIView()
    }
    
    
    @IBOutlet weak var tableFooterActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var tableFooterAppIconImageView: UIImageView!
    @IBOutlet weak var tableFooterLabel: UILabel!
    
    var loadingState: LoadingState = .Loading {
        didSet {
            switch loadingState {
            case .Finish:
                tableFooterAppIconImageView.hidden = false
                tableFooterActivityIndicatorView.hidden = true
                tableFooterLabel.hidden = true
            case .Loading:
                tableFooterActivityIndicatorView.hidden = false
                tableFooterAppIconImageView.hidden = true
                tableFooterLabel.hidden = true
            case .Failed:
                tableFooterLabel.hidden = false
                tableFooterAppIconImageView.hidden = true
                tableFooterActivityIndicatorView.hidden = true
            }
        }
    }
    

    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedRecordsController.fetchedRecords.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedRecordsController.fetchedRecords[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let record = fetchedRecordsController.fetchedRecords[indexPath.section][indexPath.row]
        guard let recordCell = cell as? RecordTableViewCell else { return }
        recordCell.record = record
    }
    
    
    
    // MARK: - Scroll View
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard fetchedRecordsController.moreComing else { return }
        let tableBottomHeight = scrollView.contentOffset.y + scrollView.bounds.height
        let contentBottomHeight = scrollView.contentSize.height
        if contentBottomHeight - tableBottomHeight < scrollView.bounds.height/2 {
            fetchedRecordsController.fetchNextPage()
        }
    }

    
    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func queryForTable() -> CKQuery {
        let query = CKQuery(recordType: recordType, predicate: queryPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: sortAscending)]
        return query
    }
    
    var fetchedRecordsController: FetchedRecordsController {
        if _fetchedRecordsController != nil { return _fetchedRecordsController! }
        _fetchedRecordsController = FetchedRecordsController(
            fetchedQuery: queryForTable(),
            recordsPerPage: recordsPerPage,
            includeCreatorUser: includeCreatorUser
        )
        _fetchedRecordsController!.delegate = self
        return _fetchedRecordsController!
    }
    
    var _fetchedRecordsController: FetchedRecordsController?
    
    
    enum LoadingState {
        case Finish
        case Loading
        case Failed
    }
}

extension CloudKitTableViewController: FetchedRecordsControllerDelegate {
    
    // Refresh Data Delegate
    func controllerWillRefreshData(controller: FetchedRecordsController) {
        print("controller Will Refresh Data")
        loadingState = .Loading
//        tableView.tableFooterView = loadPageActivityView
    }
    
    func controllerFailedToRefreshData(controller: FetchedRecordsController, error: NSError) {
        print(error.localizedDescription) ; abort()
    }
    
    func controllerDidRefreshData(controller: FetchedRecordsController) {
        print("controller Did Refresh Data")
        loadingState = .Finish
//        tableView.tableFooterView = UIView()
    }
    
    // Fetch Next Page Delegate
    func controllerWillFetchNextPage(controller: FetchedRecordsController) {
        print("controller Will Fetch Next Page")
        loadingState = .Loading
//        tableView.tableFooterView = loadPageActivityView
    }
    
    func controllerFailedToFetchNextPage(controller: FetchedRecordsController, error: NSError) {
        print(error.localizedDescription) ; abort()
    }
    
    func controllerDidFetchNextPage(controller: FetchedRecordsController) {
        print("controller Did Fetch Next Page")
        loadingState = .Finish
//        tableView.tableFooterView = UIView()
    }
    
    // Content Change Delegate
    func controllerWillChangeContent(controller: FetchedRecordsController) {
        print("controller Will Change Content")
        tableView.beginUpdates()
    }
    
    func controller(controller: FetchedRecordsController, didChangeSections sections: NSIndexSet, forChangeType type: NSFetchedResultsChangeType) {
        print("controller Did Change Sections")
        switch type {
        case .Insert:
            tableView.insertSections(sections, withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(sections, withRowAnimation: .Fade)
        default: break
        }
    }
    
    func controllerDidChangeContent(controller: FetchedRecordsController) {
        print("controller Did Change Content")
        tableView.endUpdates()
    }
}





