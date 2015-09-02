//
//  ExperimentDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import CloudKit


class ExperimentDetailViewController: RecordDetailViewController {


    // MARK: - Properties

    var experiment: CKRecord? {
        get { return record }
        set { record = newValue
            title = newValue?[ExperimentKey.Title] as? String
        }
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        guard case .New = editeState else { return }
        guard beenHerebefore == false else { return }
        beenHerebefore = true
        tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
    }
    
    var beenHerebefore = false
    
    // MARK: - View Configure

    
    @IBOutlet var likeBarButtonItem: SwitchBarButtonItem!
    
    override func configureBarButtons() {
        switch editeState {
        case .New:
            navigationItem.leftBarButtonItem = closeBarButtonItem
            navigationItem.leftBarButtonItem?.title = "Cancel"
//            navigationController?.popoverPresentationController?.backgroundColor = DefaultStyleController.Color.GroupTableViewBackGround
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            toolbarItems = nil
            
        case .Read:
            showCloseBarButtonItemIfNeeded()
            if imCreator {
                navigationItem.rightBarButtonItems = [editButtonItem()]
                toolbarItems = nil
            } else {
                navigationItem.rightBarButtonItems = nil
                self.likeBarButtonItem.on = AppDelegate.Cloud.Manager.amILikingThisExperiment(experiment!)
            }
            
        case .Write:
            navigationItem.leftItemsSupplementBackButton = false
            navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: UIView())]
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [flexibleSpaceBarButtonItem, deleteBarButtonItem]
        }
        
    }
    
    // MARK: - @IBAction

    @IBAction func toggleLikeState(sender: SwitchBarButtonItem) {
        let unLike = !sender.on
        if unLike {
            doLike()
        } else {
            doUnLike()
        }
    }
    
    private func doLike() {
        self.setToolbarItems([activityBarButtonItem], animated: true)
        AppDelegate.Cloud.Manager.likeExperiment(experiment!) {
            (error) in
            self.setToolbarItems([self.likeBarButtonItem], animated: true)
            guard error == nil else { print(error!.localizedDescription) ; return }
            self.likeBarButtonItem.on = true
        }
        
        
        
    }
    
    private func doUnLike() {
        self.setToolbarItems([activityBarButtonItem], animated: true)
        AppDelegate.Cloud.Manager.unLikeExperiment(experiment!) {
            (error) in
            self.setToolbarItems([self.likeBarButtonItem], animated: true)
            guard error == nil else { print(error!.localizedDescription) ; return }
            self.likeBarButtonItem.on = false
        }
    }
    
    
    // MARK: - Table View Data Struct

    private enum RowInfo: ReusableCellInfo {
        case Basic(key:String)
        case RightDetail(key:String)
        case User(key:String)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return "BasicCell"
            case .RightDetail(_):
                return "RightDetailCell"
            case .User(_):
                return "UserCell"
            }
        }
        
        
        var key: String? {
            switch self {
            case .Basic(let key):
                return key
            case .RightDetail(let key):
                return key
            case .User(let key):
                return key
            }
        }
        

    }
    

    override func setupSections() -> [SectionInfo] {
        var result = [SectionInfo]()
        // Sections 1: OverView
        let titleRow: RowInfo = RowInfo.RightDetail(key: ExperimentKey.Title)
        let bodyRow: RowInfo = .RightDetail(key: ExperimentKey.Body)
        var rows: [ReusableCellInfo] = [titleRow, bodyRow]
        if editing == false {
            let creationDateRow: RowInfo = .RightDetail(key: RecordKey.CreationDate)
            rows.append(creationDateRow)
        }
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: rows)
        result.append(overViewSectionInfo)
        
        // Sections 2: Author
        if editing == false {
            let authorRow: RowInfo = .User(key: RecordKey.CreatorUserRecordID)
            let authorSectionInfo = SectionInfo(title: "Author", rows: [authorRow])
            result.append(authorSectionInfo)
            
        }
        
        // Sections 3: Related
        if editing == false {
            let reviewsRow: RowInfo = .Basic(key: "Reviews")
            let fansRow: RowInfo = .Basic(key: "Fans")
            let relateSectionInfo = SectionInfo(title: "Related", rows: [reviewsRow, fansRow])
            result.append(relateSectionInfo)
        }
        return result
    }
    
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        super.configureCell(cell, atIndexPath: indexPath)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        switch rowInfo {
        case .Basic(let key):
            cell.textLabel!.text = key
        case .RightDetail(let key):
            cell.textLabel!.text = labelTextByKey[key]
            let text = key == RecordKey.CreationDate ?
                experiment?.stringForCreationDate :
                (experiment?[key] as? CustomStringConvertible)?.description
            cell.detailTextLabel!.text = text ?? " " // For debug. nil cause the cell not update
            cell.accessoryType = editing ? .DisclosureIndicator : .None
        case .User(_):
            guard let userCell = cell as? UserTableViewCell else { break }
            userCell.record = experiment?.createdBy
        }
    }
    
    private var labelTextByKey: [String: String] {
        return [
            ExperimentKey.Title:        ExperimentKey.Title.capitalizedString,
            ExperimentKey.Body:         ExperimentKey.Body.capitalizedString,
            RecordKey.CreationDate:     "Date"
        ]
    }
    // MARK: - Table view delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let segueID = segueIDAtIndexPath(indexPath) else { return }
        performSegueWithIdentifier(segueID.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    private func segueIDAtIndexPath(indexPath: NSIndexPath) -> SegueID? {
        guard let rowInfo = sections[indexPath.section].rows[indexPath.row] as? RowInfo else { return nil }
        switch rowInfo {
        case .Basic(let key):
            return segueIDByKey[key]
            
        case .RightDetail(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        case .User(let key):
            return segueIDByKey[key]
            
        }
    }
    
    private var segueIDByKey: [String: SegueID] {
        return [
            "Reviews":                  .ShowReviews,
            "Fans":                     .ShowFans,
            ExperimentKey.Title:        .EditeText,
            ExperimentKey.Body:         .EditeText,
        ]
    }
    
    
    // MARK: - Segue


    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController else { return }
            udvc.user = experiment?.createdBy
            
        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate =  NSPredicate(format: "%K = %@", ReviewKey.ReviewTo, experiment!)
            
        case .ShowFans:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            let toPredicate = NSPredicate(format: "%K = %@", LinkKey.To, experiment!)
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserLikeExperiment.rawValue)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [toPredicate, typePredicate])
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let indexPath = tableView.indexPathForCell((sender as! UITableViewCell))! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.text = experiment![rowInfo.key!] as? String
            ettvc.title = labelTextByKey[rowInfo.key!]
            
            ettvc.doneBlock = {
                self.experiment![rowInfo.key!] = ettvc.text;
                self.configureCell(self.tableView.cellForRowAtIndexPath(indexPath)!, atIndexPath: indexPath)
            }
            
        }
    }
    
    private enum SegueID: String {
        case ShowUserDetail
        case ShowReviews
        case ShowFans
        case EditeText
    }
    
}










