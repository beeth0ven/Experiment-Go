//
//  RecordDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

protocol ReusableCellInfo {
    var cellReuseIdentifier: String { get }
}

@IBDesignable

class RecordDetailViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate  {
    
    var record: CKRecord?

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

    @IBAction func close(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var recordInserted = false { didSet { editing = recordInserted } }


    // MARK: - @IBAction

    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard recordInserted == false else { return }
        tableView.editing = editing
        
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
        })
    }

    // MARK: - View Configure
    
    func configureBarButtons() {
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = CGFloat.DefaultTableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    
    func updateVisibleCells() {
        for cell in self.tableView.visibleCells {
            self.configureCell(cell, atIndexPath: self.tableView.indexPathForCell(cell)!)
        }
    }
    

    
    // MARK: - View Controller State
    
    enum EditeState {
        case New
        case Read
        case Write
    }
    
    
    var imCreator: Bool {
        guard let record = record else { return false }
        guard let recordID = record.creatorUserRecordID else { return true }
        guard let currentUserRecordID = AppDelegate.Cache.Manager.currentUser()?.recordID else { return false }
        if recordID.recordName == CKOwnerDefaultName { return true }
        return recordID == currentUserRecordID
    }
    
    var editeState: EditeState {
        //        print("imCreator: \(imCreator)")
        guard imCreator else { return .Read }
        if recordInserted { return .New }
        if editing { return .Write }
        return .Read
    }
    

    
    // MARK: - Table View Data Source
    
    
    var sections: [SectionInfo] {
        if _sections != nil { return _sections! }
        _sections = setupSections()
        return _sections!
    }
    
    var _sections: [SectionInfo]?
    
    func setupSections() -> [SectionInfo] {
        return [SectionInfo]()
    }

    struct SectionInfo {
        var title: String
        var rows: [ReusableCellInfo]
        
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return  sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reusableCellInfo = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableCellInfo.cellReuseIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
//    // MARK: - Table View Delegate
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let reusableCellInfo = sections[indexPath.section].rows[indexPath.row]
//        guard let segueIdentifier = reusableCellInfo.segueIdentifier else { return }
//        performSegueWithIdentifier(segueIdentifier, sender: tableView.cellForRowAtIndexPath(indexPath))
//    }
    
    
    // MARK: - Table View Editing
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    
}

extension CGFloat {
    static let DefaultTableViewEstimatedRowHeight: CGFloat = 44
}

