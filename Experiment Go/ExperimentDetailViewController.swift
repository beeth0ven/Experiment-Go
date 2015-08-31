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
        set { record = newValue }
    }


    // MARK: - View Configure

    
    @IBOutlet var likeBarButtonItem: SwitchBarButtonItem! {
        didSet {
            likeBarButtonItem.offStateTitle = "Like"
            likeBarButtonItem.onStateTitle = "Liking"
        }
    }
    
    override func configureBarButtons() {
        super.configureBarButtons()
        switch editeState {
        case .New:
            navigationItem.leftBarButtonItem?.title = "Cancel"
//            navigationController?.popoverPresentationController?.backgroundColor = DefaultStyleController.Color.GroupTableViewBackGround
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            toolbarItems = nil
            
        case .Read:
            if closeBarButtonItem != nil { navigationItem.leftBarButtonItems = [closeBarButtonItem!] }
            if imCreator {
                navigationItem.rightBarButtonItems = [editButtonItem()]
                toolbarItems = nil
            } else {
                navigationItem.rightBarButtonItems = nil
                toolbarItems = [activityBarButtonItem]
                AppDelegate.Cloud.Manager.amILikingThisExperiment(experiment!) {
                    (liking)  in
                    self.likeBarButtonItem.on = liking
                    self.setToolbarItems([self.likeBarButtonItem], animated: true)
                }
            }
            
        case .Write:
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [flexibleSpaceBarButtonItem, deleteBarButtonItem]
        }
        
    }
    
    // MARK: - @IBAction

    @IBAction func toggleLikeState(sender: SwitchBarButtonItem) {
        self.setToolbarItems([activityBarButtonItem], animated: true)
        let unLike = !sender.on
        if unLike {
            doLike()
        } else {
            doUnLike()
        }
    }
    
    private func doLike() {
        let fanLink = CKRecord(fanLinktoExperiment: experiment!)
        AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(fanLink) {
            (fanLink, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            dispatch_async(dispatch_get_main_queue()) {
                self.likeBarButtonItem.on = true
                self.setToolbarItems([self.likeBarButtonItem], animated: true)
            }
        }
    }
    
    private func doUnLike() {
        let fanLinkRecordID = CKRecordID(fanLinktoExperiment: experiment!)
        AppDelegate.Cloud.Manager.publicCloudDatabase.deleteRecordWithID(fanLinkRecordID) {
            (_, error) in
            guard error == nil else { print(error!.localizedDescription) ; return }
            dispatch_async(dispatch_get_main_queue()) {
                self.likeBarButtonItem.on = false
                self.setToolbarItems([self.likeBarButtonItem], animated: true)
            }
        }
    }
    
    
    // MARK: - Table View Data Struct

    private enum RowInfo: ReusableCellInfo {
        case Basic(String)
        case RightDetail(String, String?)
        case User(CKRecord)
        
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
        
        var segueIdentifier: String? {
            guard case .Basic(let text) = self else { return nil }
            switch text {
            case "Reviews":
                return SegueID.ShowReviews.rawValue
            case "Fans":
                return SegueID.ShowFans.rawValue
            default: return nil
            }
        }
    }
   
    override func setupSections() -> [SectionInfo] {
        var result = [SectionInfo]()
        // Sections 1: OverView
        let titleRow: RowInfo = .RightDetail(ExperimentKey.Title.capitalizedString,experiment?[ExperimentKey.Title] as? String)
        let bodyRow: RowInfo = .RightDetail(ExperimentKey.Body.capitalizedString,experiment?[ExperimentKey.Body] as? String)
        let creationDateRow: RowInfo = .RightDetail("Date", experiment?.stringForCreationDate)
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: [titleRow, bodyRow, creationDateRow])
        result.append(overViewSectionInfo)
        
        // Sections 2: Author
        if editing == false {
            let authorRow: RowInfo = .User(experiment!.createdBy!)
            let authorSectionInfo = SectionInfo(title: "Author", rows: [authorRow])
            result.append(authorSectionInfo)
            
        }
        
        // Sections 3: Related
        if editing == false {
            let reviewsRow: RowInfo = .Basic("Reviews")
            let fansRow: RowInfo = .Basic("Fans")
            let relateSectionInfo = SectionInfo(title: "Related", rows: [reviewsRow, fansRow])
            result.append(relateSectionInfo)
        }
        return result
    }
    
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        super.configureCell(cell, atIndexPath: indexPath)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        switch rowInfo {
        case .Basic(let text):
            cell.textLabel!.text = text
        case .RightDetail(let text, let detailText):
            cell.textLabel!.text = text
            cell.detailTextLabel!.text = detailText
        case .User(let user):
            guard let userCell = cell as? UserTableViewCell else { break }
            userCell.record = user
        }
    }



    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate =  NSPredicate(format: "%K = %@", ReviewKey.ReviewTo, experiment!)
            
        case .ShowFans:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate =  NSPredicate(format: "%K = %@", FanLinkKey.ToExperiment, experiment!)
        }
    }
    
    private enum SegueID: String {
        case ShowReviews
        case ShowFans
    }
    
}

extension CKRecordID {
    convenience init(fanLinktoExperiment experiment: CKRecord) {
        let currentUser = AppDelegate.Cache.Manager.currentUser()!
        let name = String(dropFirst("\(currentUser.recordID.recordName)-like-\(experiment.recordID.recordName)".characters))
        self.init(recordName: name)
        print(name)
    }
}

extension CKRecord {
    convenience init(fanLinktoExperiment experiment: CKRecord) {
        let recordID = CKRecordID(fanLinktoExperiment: experiment)
        self.init(recordType: FanLinkKey.RecordType, recordID: recordID)
        self[FanLinkKey.ToExperiment] =  CKReference(record: experiment, action: .DeleteSelf)
    }
    
    var smartStringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.smartStringFormDate(date)
    }
    
    var stringForCreationDate: String {
        let date = creationDate ?? NSDate()
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
    }
}

