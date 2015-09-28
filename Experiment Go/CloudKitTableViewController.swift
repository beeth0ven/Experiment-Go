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

class CloudKitTableViewController: UITableViewController, TableViewControllerCellSelfSize, CurrentUserHasChangeObserver {
    
    var items = [[CKItem]]()
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableCellSelfSize()
        startObserveCurrentUserHasChange()
        refresh()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(false)
        showOrHideToolBarIfNeeded()
        showBackwardBarButtonItemIfNeeded()
    }
    
    deinit { stopObserveCurrentUserHasChange() }

    
    // MARK: - @IBAction
    
    func updateUI() { self.tableView.updateVisibleCells() }

    func refresh() { refresh(refreshControl) }
    
    @IBAction func refresh(sender: UIRefreshControl?) {
        refreshControl?.endRefreshing()
        refreshData()
        tableView.reloadData()
    }
    
    func refreshData() {
        guard !loading else { return }
        loading = true
        items.removeAll()
        let refreshOp = refreshOperation
        refreshOp.didGet = didGet
        refreshOp.didFail = didFail
        refreshOp.start()
        
    }
    
    func loadNextPage() {
        guard let loadNextPageOp = loadNextPageOperation else { return }
        guard !loading else { return }
        loading = true
        loadNextPageOp.didGet = didGet
        loadNextPageOp.didFail = didFail
        loadNextPageOp.start()
    }
    
    func didGet(objects: [CKItem],cursor: CKQueryCursor?) {
        loading = false
        self.items.append(objects)
        tableView.appendASection()
        lastCursor = cursor
    }
    
    func didFail(error: NSError) {
        loading = false
        handleFail(error)
    }
    
    var refreshOperation: GetCKItemsOperation {
        let query = CKQuery(recordType: RecordType.Experiment.rawValue )
        return GetObjectsWithCreatorUserOperation(type: .Refresh(query))
    }
    
    var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return GetObjectsWithCreatorUserOperation(type: .GetNextPage(cursor))
    }
    
    var lastCursor: CKQueryCursor?
    var loading = false { didSet { loading ? beginRefresh() : endRefresh() } }

    // MARK: - Table view data source
    @IBInspectable
    var cellReusableIdentifier: String?

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifier!, forIndexPath: indexPath) as! CKItemTableViewCell
        cell.item = items[indexPath.section][indexPath.row]
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Scroll View
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        guard lastCursor != nil else { return }
        let tableBottomHeight = scrollView.contentOffset.y + scrollView.bounds.height
        let contentBottomHeight = scrollView.contentSize.height
        if contentBottomHeight - tableBottomHeight < scrollView.bounds.height/2 {
            loadNextPage()
        }
    }

    
    @IBOutlet weak var tableFooterActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var tableFooterAppIconImageView: UIImageView!
    
    enum FetchType: String {
        case ObjectsWithCreatorUser
    }
}

extension UITableView {
    func appendASection() {
        insertSections(NSIndexSet(index: numberOfSections), withRowAnimation: .Fade)
    }
    
    static var DefaultEstimatedRowHeight: CGFloat { return 66 }

}


protocol TableViewControllerCellSelfSize {
    var tableView: UITableView! { get set }
    func enableCellSelfSize()
}

extension TableViewControllerCellSelfSize {
    func enableCellSelfSize(){
        tableView.estimatedRowHeight = UITableView.DefaultEstimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
}


protocol Refreshable {
    func beginRefresh()
    func endRefresh()
}

extension CloudKitTableViewController: Refreshable {
    func beginRefresh() {
        tableFooterActivityIndicatorView.hidden = false
        tableFooterAppIconImageView.hidden = true
    }
    
    func endRefresh() {
        tableFooterActivityIndicatorView.hidden = true
        tableFooterAppIconImageView.hidden = false
    }
}

extension UITableView {
    func updateVisibleCells() { reloadRowsAtIndexPaths(indexPathsForVisibleRows!, withRowAnimation: .Fade) }
}

