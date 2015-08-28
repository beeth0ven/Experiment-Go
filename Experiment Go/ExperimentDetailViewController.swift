//
//  ExperimentDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import CloudKit


@IBDesignable

class ExperimentDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
    struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
    }
    
    
    // MARK: - Properties

    var experiment: CKRecord? 

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editing = experimentInserted
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.showOrHideToolBarIfNeeded()
        setBarSeparatorHidden(true)
    }
    
    // MARK: - View Configure
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var addNewReviewBarButtonItem: UIBarButtonItem!
    @IBOutlet var likeBarButtonItem: SwitchBarButtonItem! {
        didSet {
            likeBarButtonItem.offStateTitle = "Like"
            likeBarButtonItem.onStateTitle = "Liking"
        }
    }
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var flexibleSpaceBarButtonItem: UIBarButtonItem!
    
    lazy var activityBarButtonItem: UIBarButtonItem = {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorView.startAnimating()
        let result = UIBarButtonItem(customView: activityIndicatorView)
        result.customView!.frame = CGRect.BarButtonItemDefaultRect
        return result
    }()
    
    
    func configureBarButtons() {
        switch editeState {
        case .New:
            navigationController?.popoverPresentationController?.backgroundColor = DefaultStyleController.Color.GroupTableViewBackGround
            navigationItem.leftBarButtonItems = [cancelBarButtonItem]
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            toolbarItems = nil
            
        case .Read:
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
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
    
    func updateVisibleCells() {
        for cell in self.tableView.visibleCells {
            self.configureCell(cell, atIndexPath: self.tableView.indexPathForCell(cell)!)
        }
    }

    // MARK: - View Controller State
    
    private enum EditeState {
        case New
        case Read
        case Write
    }
    
    var experimentInserted = false
    
    private var imCreator: Bool {
        guard let experiment = experiment else { return false }
        guard let recordID = experiment.creatorUserRecordID else { return true }
        guard let currentUserRecordID = AppDelegate.Cache.Manager.currentUser()?.recordID else { return false }
//        print("experiment recordID: \(recordID.recordName)")
//        print("currentUser recordID: \(currentUserRecordID.recordName)")
        if recordID.recordName == CKOwnerDefaultName { return true }
        return recordID == currentUserRecordID
    }
    
    private var editeState: EditeState {
//        print("imCreator: \(imCreator)")
        guard imCreator else { return .Read }
        if experimentInserted { return .New }
        if editing { return .Write }
        return .Read
    }
    
    // MARK: - @IBAction

    @IBAction func close(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        guard experimentInserted == false else { return }
        tableView.editing = editing
        
        self._sections = nil
        self.configureBarButtons()
        
        let indexSet = NSIndexSet(indexesInRange: NSRange(location: 1, length: 2))
        if editing {
            tableView.deleteSections(indexSet, withRowAnimation: .Fade)
        } else {
            tableView.insertSections(indexSet, withRowAnimation: .Fade)
        }
        updateVisibleCells()

    }

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
    
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
//        case .AddExperiment:
//            guard let edvc = segue.destinationViewController.contentViewController as? ExperimentDetailViewController else { return }
//            let experiment = CKRecord(recordType: CloudManager.ExperimentKey.RecordType)
//            edvc.experiment = experiment
//            
        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? ReviewsTableViewController else { return }
            rtvc.reviewTo = experiment
        case .ShowFans:
            guard let ftvc = segue.destinationViewController.contentViewController as? FansTableViewController else { return }
            ftvc.likedExperiment = experiment
        }
    }
    
    private enum SegueID: String {
        case ShowReviews
        case ShowFans
    }
    
    // MARK: - Table View Data Source
    
    
    var sections: [SectionInfo] {
        if _sections != nil { return _sections! }
        _sections = [SectionInfo]()
        
        // Sections 1: OverView
        let titleRow: RowInfo = .RightDetail(ExperimentKey.Title.capitalizedString,experiment?[ExperimentKey.Title] as? String)
        let bodyRow: RowInfo = .RightDetail(ExperimentKey.Body.capitalizedString,experiment?[ExperimentKey.Body] as? String)
        let creationDateRow: RowInfo = .RightDetail("Post Date", experiment?.stringForCreationDate)
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: [titleRow, bodyRow, creationDateRow])
        _sections!.append(overViewSectionInfo)
        
        // Sections 2: Author
        if editing == false {
            let authorRow: RowInfo = .User(experiment!.createdBy!)
            let authorSectionInfo = SectionInfo(title: "Author", rows: [authorRow])
            _sections!.append(authorSectionInfo)
            
        }
        
        // Sections 3: Related
        if editing == false {
            let reviewsRow: RowInfo = .Basic("Reviews")
            let fansRow: RowInfo = .Basic("Fans")
            let relateSectionInfo = SectionInfo(title: "Relate", rows: [reviewsRow, fansRow])
            _sections!.append(relateSectionInfo)
        }
        return _sections!
    }
    
    var _sections: [SectionInfo]?
    
    struct SectionInfo {
        var title: String
        var rows: [RowInfo]
        
    }
    
    enum RowInfo {
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
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return  sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return sections[section].rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowInfo = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(rowInfo.cellReuseIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let rowInfo = sections[indexPath.section].rows[indexPath.row]
        switch rowInfo {
        case .Basic(let text):
            cell.textLabel!.text = text
        case .RightDetail(let text, let detailText):
            cell.accessoryType = editing ? .DisclosureIndicator : .None
            cell.textLabel!.text = text
            cell.detailTextLabel!.text = detailText
        case .User(let user):
            guard let userCell = cell as? UserTableViewCell else { break }
            userCell.record = user
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    // MARK: - Table View Editing 
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let rowInfo = sections[indexPath.section].rows[indexPath.row]
        guard case .Basic(let text) = rowInfo else { return }
        if text == "Reviews" { performSegueWithIdentifier(SegueID.ShowReviews.rawValue, sender: nil) }
        if text == "Fans" { performSegueWithIdentifier(SegueID.ShowFans.rawValue, sender: nil) }

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

