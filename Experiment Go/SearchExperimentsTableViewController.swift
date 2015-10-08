//
//  SearchExperimentsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit


class SearchExperimentsTableViewController: ExperimentsTableViewController {

    @IBInspectable
    var showSearchBar: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchResultsController = searchController.searchResultsController as! SearchResultsController
        searchResultsController.didGet = { self.searchText = $0 }
    }
    
    var searchText : String?  {
        didSet {
            self.searchController.active = false
            guard searchText != oldValue else { return }
            searchController.searchBar.text = searchText
            refresh()
        }
    }
    
    override func loadView() { super.loadView() ; if showSearchBar { self.tableView.tableHeaderView = searchController.searchBar } }
    
    override var refreshOperation: GetCKItemsOperation {
        return SearchExperimentsOperation(searchText: searchText)
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return SearchExperimentsOperation(type: .GetNextPage(cursor))
    }
    
    lazy var searchController: UISearchController = {
        // SearchResultsController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let searchResultsController = storyboard.instantiateViewControllerWithIdentifier("SearchResults") as! SearchResultsController
        
        // SearchController
        var result = UISearchController(searchResultsController: searchResultsController)
        result.delegate = searchResultsController
        result.view.layer.cornerRadius = 5
        result.view.layer.masksToBounds = true
        
        // SearchBar
        result.searchBar.delegate = searchResultsController
        result.searchBar.text = self.searchText
        result.searchBar.placeholder = NSLocalizedString("Search by tag", comment: "")
        result.searchBar.searchBarStyle = .Minimal
        result.searchBar.backgroundColor = UIColor.whiteColor()
        result.searchBar.sizeToFit()
        result.view.backgroundColor = UIColor.clearColor()
        self.definesPresentationContext = true
        return result
        }()
    
}