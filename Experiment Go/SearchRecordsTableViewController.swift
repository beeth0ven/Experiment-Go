//
//  SearchRecordsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/11/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit
import CoreData


class SearchRecordsTableViewController: RecordsTableViewController, UISearchBarDelegate, UISearchControllerDelegate {
    
    lazy var searchController: UISearchController = {
        // SearchResultsController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let searchResultsController = storyboard.instantiateViewControllerWithIdentifier("SearchResults") as! SearchResultsController
        
        // SearchController
        var result = UISearchController(searchResultsController: searchResultsController)
        result.delegate = searchResultsController
        
        // SearchBar
        result.searchBar.delegate = searchResultsController
        result.searchBar.text = self.searchText
        result.searchBar.placeholder = "Use space to separate keywords."
        result.searchBar.searchBarStyle = .Minimal
        result.searchBar.backgroundColor = UIColor.whiteColor()
        result.searchBar.sizeToFit()
        self.definesPresentationContext = true
        return result
    }()
    
    override func loadView()    { super.loadView()     ; self.tableView.tableHeaderView = searchController.searchBar  }
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchResultsController = searchController.searchResultsController as! SearchResultsController
        searchResultsController.searthTextDidSelected = { (text) in self.searchController.active = false ; self.searchText = text }
    }
    override func viewWillAppear(animated: Bool) {  super.viewWillAppear(animated) ; navigationController?.hidesBarsOnSwipe = false }

    var searchText : String?  {
        didSet {
            guard searchText != oldValue else { return }
            queryPredicate = predicateForSearchText(searchText)
            searchController.searchBar.text = searchText
            refresh()
        }
    }
    
    private func predicateForSearchText(searchText: String?) -> NSPredicate {
        let texts: [String] = String.isBlank(searchText) ? [] : searchText!.lowercaseString.componentsSeparatedByString(" ")
        guard texts.count > 0 else { return NSPredicate(value: true) }
        let subPredicates = texts.map { NSPredicate(format: "%K CONTAINS %@", ExperimentKey.Tags , $0) }
        return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
    }
    
}