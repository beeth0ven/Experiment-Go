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
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            toolbarItems = nil
            
        case .Read:
            showCloseBarButtonItemIfNeeded()
            if imCreator {
                navigationItem.rightBarButtonItems = [editButtonItem()]
                toolbarItems = nil
            } else {
                navigationItem.rightBarButtonItems = nil
                likeBarButtonItem.on = AppDelegate.Cloud.Manager.amILikingThisExperiment(experiment!)
                toolbarItems = [likeBarButtonItem]
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
        case SubTitle(key:String)
        case Collection(key:String)
        case RightDetail(key:String)
        case User(key:String)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return "BasicCell"
            case .SubTitle(_):
                return "SubTitleCell"
            case .Collection(_):
                return "CollectionCell"
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
            case .SubTitle(let key):
                return key
            case .Collection(let key):
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
        var overViewSectionRows = [ReusableCellInfo]()
        let titleRow: RowInfo = RowInfo.RightDetail(key: ExperimentKey.Title)
        overViewSectionRows.append(titleRow)
        if shouldAddRowForKey(ExperimentKey.Tags) { overViewSectionRows.append(RowInfo.Collection(key: ExperimentKey.Tags)) }
        if editing == false {
            let creationDateRow: RowInfo = .RightDetail(key: RecordKey.CreationDate)
            overViewSectionRows.append(creationDateRow)
        }
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: overViewSectionRows)
        result.append(overViewSectionInfo)
        
        // Sections 2: Author
        if editing == false {
            let authorRow: RowInfo = .User(key: RecordKey.CreatorUserRecordID)
            let authorSectionInfo = SectionInfo(title: "Author", rows: [authorRow])
            result.append(authorSectionInfo)
            
        }
        
        // Sections 3: Body
        let keys = [
            ExperimentKey.Purpose ,
            ExperimentKey.Principle,
            ExperimentKey.Content,
            ExperimentKey.Steps,
            ExperimentKey.Results
        ]
        let bodySectionRows: [ReusableCellInfo] = keys.flatMap { shouldAddRowForKey($0) ? RowInfo.SubTitle(key: $0) : nil }
        if bodySectionRows.count > 0 { let bodySectionInfo = SectionInfo(title: "Body", rows: bodySectionRows) ; result.append(bodySectionInfo) }

        // Sections 4: Conclusion
        if shouldAddRowForKey(ExperimentKey.Conclusion) {
            let conclusionRow : RowInfo = .SubTitle(key: ExperimentKey.Conclusion)
            let conclusionSectionInfo = SectionInfo(title: "Conclusion", rows: [conclusionRow])
            result.append(conclusionSectionInfo)
        }

        
        // Sections 5: Foot Note
        if shouldAddRowForKey(ExperimentKey.FootNote) {
            let footNoteRow : RowInfo = .SubTitle(key: ExperimentKey.FootNote)
            let footNoteSectionInfo = SectionInfo(title: "FootNote", rows: [footNoteRow])
            result.append(footNoteSectionInfo)
        }

        // Sections 6: Related
        if editing == false {
            let reviewsRow: RowInfo = .Basic(key: "Reviews")
            let fansRow: RowInfo = .Basic(key: "Fans")
            let relateSectionInfo = SectionInfo(title: "Related", rows: [reviewsRow, fansRow])
            result.append(relateSectionInfo)
        }
        return result
    }
    
    private func shouldAddRowForKey(key: String) -> Bool { return editing  ? true : experiment?[key] != nil }
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        super.configureCell(cell, atIndexPath: indexPath)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        switch rowInfo {
        case .Basic(let key):
            cell.textLabel!.text = key
        case .SubTitle(let key):
            guard let subTitleCell = cell as? SubTitleTableViewCell else { return }
            subTitleCell.titleLabel.text = labelTextByKey[key]
            let text = textForExperimentKey(key)
            subTitleCell.subTttleLabel.text = text ?? " "
            subTitleCell.accessoryType = editing ? .DisclosureIndicator : .None
            
        case .Collection(let key):
            guard let collectionCell = cell as? TagsTableViewCell else { return }
            collectionCell.tags = experiment?[key] as? [String] ?? []
            collectionCell.collectionView.userInteractionEnabled = editing ? false : true
            collectionCell.accessoryType = editing ? .DisclosureIndicator : .None

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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        guard case .Collection(_) = rowInfo else { return UITableViewAutomaticDimension }
        return 80
    }
    
    
    private var labelTextByKey: [String: String] {
        return [
            ExperimentKey.Title:        ExperimentKey.Title.capitalizedString,
            ExperimentKey.Conclusion:   ExperimentKey.Conclusion.capitalizedString,
            ExperimentKey.Content:      ExperimentKey.Content.capitalizedString,
            ExperimentKey.Principle:    ExperimentKey.Principle.capitalizedString,
            ExperimentKey.Purpose:      ExperimentKey.Purpose.capitalizedString,
            ExperimentKey.Results:      ExperimentKey.Results.capitalizedString,
            ExperimentKey.Steps:        ExperimentKey.Steps.capitalizedString,
            ExperimentKey.Tags:         ExperimentKey.Tags.capitalizedString,
            ExperimentKey.FootNote:     "Foot Note",
            RecordKey.CreationDate:     "Date",
        ]
    }
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = sections[section].title
        return ["FootNote", "Conclusion"].contains(title) ?  nil : title
    }
    // MARK: - Table view delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let segueID = segueIDAtIndexPath(indexPath) else { return }
        self.performSegueWithIdentifier(segueID.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    private func segueIDAtIndexPath(indexPath: NSIndexPath) -> SegueID? {
        guard let rowInfo = sections[indexPath.section].rows[indexPath.row] as? RowInfo else { return nil }
        switch rowInfo {
        case .Basic(let key):
            return segueIDByKey[key]
            
        case .SubTitle(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        case .Collection(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        case .RightDetail(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        case .User(let key):
            return segueIDByKey[key]
            
        }
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
            rtvc.queryPredicate = NSPredicate.predicateForReviewToExperiment(experiment!)
            
        case .ShowFans:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate = NSPredicate.predicateForFanLinkToExperiment(experiment!)
            
        case .ShowExperimentsByTag:
            guard let srtvc = segue.destinationViewController.contentViewController as? SearchRecordsTableViewController else { return }
            srtvc.searchText = (sender as! UIButton).currentTitle
            srtvc.title = srtvc.searchText
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let indexPath = tableView.indexPathForCell((sender as! UITableViewCell))! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.text = textForExperimentKey(rowInfo.key!)
            ettvc.title = labelTextByKey[rowInfo.key!]
            
            ettvc.doneBlock = {
                (text) in
                self.setText(text, ForExperimentKey: rowInfo.key!)
                if rowInfo.key! ==  ExperimentKey.Title { self.title = text }
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
        case .EditeTags:
            guard let etcvc = segue.destinationViewController.contentViewController as? EditeTagsCollectionViewController else { return }
            let tagsTableViewCell = sender as! TagsTableViewCell
            etcvc.tags = tagsTableViewCell.tags ?? []
            etcvc.title = tagsTableViewCell.titleLabel.text
            
            etcvc.doneBlock = {
                (tags) in
                guard tags != tagsTableViewCell.tags ?? [] else { return }
                self.experiment?[ExperimentKey.Tags] = tags
                self.tableView.reloadRowsAtIndexPaths([self.tableView.indexPathForCell(tagsTableViewCell)!], withRowAnimation: .Fade)

            }
        }
    }
    
    private func textForExperimentKey(key: String) -> String? {
        if (key == ExperimentKey.Tags) {
            return (experiment?[key] as? [String])?.joinWithSeparator(" ")
        } else {
            return (experiment?[key] as? CustomStringConvertible)?.description
        }
    }
    
    private func setText(text: String?, ForExperimentKey key: String) {
        if (key == ExperimentKey.Tags) {
            experiment?[key] = text?.lowercaseString.componentsSeparatedByString(" ").filter{ $0.removeWhitespace() != "" }
        } else {
            experiment?[key] = text
        }
    }
    
    private var segueIDByKey: [String: SegueID] {
        return [
            "Reviews":                  .ShowReviews,
            "Fans":                     .ShowFans,
            ExperimentKey.Title:        .EditeText,
            ExperimentKey.Conclusion:   .EditeText,
            ExperimentKey.Content:      .EditeText,
            ExperimentKey.Principle:    .EditeText,
            ExperimentKey.Purpose:      .EditeText,
            ExperimentKey.Results:      .EditeText,
            ExperimentKey.Steps:        .EditeText,
            ExperimentKey.FootNote:     .EditeText,
            ExperimentKey.Tags:         .EditeTags,

        ]
    }
    
    
    private enum SegueID: String {
        case ShowUserDetail
        case ShowReviews
        case ShowFans
        case ShowExperimentsByTag
        case EditeText
        case EditeTags
    }
    
}


extension String {
    func replace(string: String, with replacement: String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: .LiteralSearch, range: nil)
    }
    
    func removeWhitespace() -> String {
        return replace(" ", with: "")
    }
}







