//
//  ItemDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/22/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

class ItemDetailViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate, TableViewControllerCellSelfSize  {
    
    var item: CKItem? { didSet { title = item?.displayTitle } }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(true)
        showOrHideToolBarIfNeeded()
    }
    
    // MARK: - View Configure
    
    func configureBarButtons() { }
    
    // MARK: - @IBAction
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.editing = editing
        if !editing && item?.hasChange == true {
            item?.saveInBackground(didFail: handleFail)
        }
        animatedReloadData()
    }
    
    private func animatedReloadData() {
        let tableFooterView = tableView.tableFooterView ; tableView.tableFooterView = nil // Transition become smooth.
        let options: UIViewAnimationOptions =  editing ? .TransitionCurlUp : .TransitionCurlDown
        UIView.transitionWithView(navigationController!.view,
            duration: 0.4,
            options: options,
            animations: {
                self._sections = nil
                self.tableView.reloadData()
            },
            completion: { (_) in
                self.configureBarButtons()
                self.showOrHideToolBarIfNeeded()
                self.tableView.tableFooterView = tableFooterView
        })
    }
    
    // MARK: - Table View Data Source
    @IBOutlet weak var tableView: UITableView! { didSet { enableCellSelfSize() } }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return  sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reusableCellInfo = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableCellInfo.cellReuseIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, forKey: reusableCellInfo.key)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forKey key: String) { }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    // MARK: - Table View Editing
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    
    // MARK: - Table View Data struct

    var sections: [SectionInfo] {
        if _sections != nil { return _sections! }
        _sections = setupSections()
        return _sections!
    }
    
    var _sections: [SectionInfo]?
    
    func setupSections() -> [SectionInfo] { return [SectionInfo]() }
    
    
    enum EditeState {
        case New
        case Read
        case Write
    }
}

struct SectionInfo {
    var title: String
    var rows: [ReusableCellInfo]
}

protocol ReusableCellInfo {
    var cellReuseIdentifier: String { get }
    var key: String { get }
}

