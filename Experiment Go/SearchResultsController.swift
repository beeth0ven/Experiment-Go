//
//  SearchResultsController.swift
//  Experiment Go
//
//  Created by luojie on 9/13/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit


class SearchResultsController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate {
    
    let historyManager = HistoryManager()
    
    var didGet: ((String?) -> ())?
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int                    { return historyManager.experimentSearchHistories.count > 0 ? 1 : 0 }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  { return historyManager.experimentSearchHistories.count }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        cell.textLabel?.text = historyManager.experimentSearchHistories[indexPath.row]
        return cell
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return "History".localizedString }
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) { callBack(tableView.cellForRowAtIndexPath(indexPath)!.textLabel!.text!) }
    
    // MARK: - UISearch Controller
    func searchBarSearchButtonClicked(searchBar: UISearchBar) { searchBar.resignFirstResponder() ; callBack(searchBar.text!) }
    
    private func callBack(selectedText: String){
        didGet?(selectedText)
        historyManager.addSearchText(selectedText)
        tableView.reloadData()
    }
    
    func didDismissSearchController(searchController: UISearchController) { if String.isBlank(searchController.searchBar.text) { didGet?(nil)} }
}

extension String { static func isBlank(text: String?) -> Bool { return text == nil ? true : text!.isEmpty } }