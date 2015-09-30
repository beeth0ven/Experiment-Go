//
//  ExperimentDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/22/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit


class ExperimentDetailViewController: ItemDetailViewController {
    
    var experiment: CKExperiment? {
        get { return item as? CKExperiment }
        set { item = newValue }
    }
    
    var delete: ((CKExperiment) -> Void)?

    override func configureBarButtons() {
        showBackwardBarButtonItemIfNeeded()
        if experiment?.createdByMe == true {
            // createdByMe
            navigationItem.rightBarButtonItem = editButtonItem()
            if !editing {
                toolbarItems = nil
            } else {
                navigationItem.hideLeftBarButtonItems()
                toolbarItems = [flexibleSpaceBarButtonItem, deleteBarButtonItem]
            }
        } else {
            toolbarItems = [likeBarButtonItem]
        }
    }
    
    override func configureCell(cell: UITableViewCell, forKey key: String) {
        let rowInfo = RowInfo(rawValue: key)!
        switch rowInfo {
        case .title:
            cell.title = key.capitalizedString
            cell.subTitle = experiment?.title
            cell.accessoryType = editing ? .DisclosureIndicator : .None
            
        case .creationDate:
            cell.title = "Date"
            cell.subTitle = experiment?.creationDate.string
            
        case .tags:
            let collectionCell = cell as! TagsTableViewCell
            collectionCell.tags = experiment?.tags ?? []
            collectionCell.collectionView.userInteractionEnabled = editing ? false : true
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .purpose, .principle, .content, .steps, .results, .conclusion, .footNote:
            cell.title = key.capitalizedString
            cell.subTitle = experiment?[key] as? String
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .reviews, .fans:
            cell.title = key.capitalizedString
            
        case .author:
            let userCell = cell as! UserTableViewCell
            userCell.user = experiment?.creatorUser
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title == "Author" ? "Author" : nil
    }
    
    override func setupSections() -> [SectionInfo] {
        let infos = !editing ? sectionInfos : sectionInfosWhileEditing
        return  infos.map { SectionInfo(title: $0.title, rows: $0.reusableCellInfos) }
    }
    
    private var sectionInfos: [(title: String, reusableCellInfos: [ReusableCellInfo])] {
        return allSectionInfos.flatMap {
            if ["Author", "Related"].contains($0.title) { return  $0 }
            let reusableCellInfos = $0.reusableCellInfos.filter { self.experiment?[$0.key]  != nil }
            return reusableCellInfos.count > 0 ? (title: $0.title, reusableCellInfos: reusableCellInfos) : nil
        }
    }
    
    private var sectionInfosWhileEditing: [(title: String, reusableCellInfos: [ReusableCellInfo])] {
        return allSectionInfos.filter {  ["Author", "Related"].contains($0.title) == false }
    }

    private var allSectionInfos: [(title: String, reusableCellInfos: [ReusableCellInfo])] = [
        
        ("OverView", [
            RowInfo.title,
            RowInfo.tags,
            RowInfo.creationDate
            ]
        ),
        
        ("Author",[
            RowInfo.author
            ]
        ),
        
        ("Body",[
            RowInfo.purpose,
            RowInfo.principle,
            RowInfo.content,
            RowInfo.steps,
            RowInfo.results,
            ]
        ),
        
        ("Conclusion",[
            RowInfo.conclusion
            ]
        ),
        
        ("FootNote",[
            RowInfo.footNote
            ]
        ),
        
        ("Related",[
            RowInfo.reviews,
            RowInfo.fans
            ]
        ),
        
    ]
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        if let segueID = !editing ? rowInfo.segueID : rowInfo.segueIDWhileEditing {
            performSegueWithIdentifier(segueID.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        if case .tags = rowInfo { return 80 } else { return UITableViewAutomaticDimension }
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController else { return }
            udvc.user = experiment?.creatorUser

        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? ReviewsTableViewController else { return }
            rtvc.reviewTo = experiment
            
        case .ShowFans:
            guard let utvc = segue.destinationViewController.contentViewController as? UsersTableViewController else { return }
            utvc.queryType = .FansBy(experiment!)
            
        case .ShowExperimentsByTag:
            guard let setvc = segue.destinationViewController.contentViewController as? SearchExperimentsTableViewController else { return }
            setvc.searchText = (sender as! UIButton).currentTitle
            setvc.title = setvc.searchText
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.title = cell.title
            ettvc.text = cell.subTitle?.stringByTrimmingWhitespace
            
            ettvc.done = {
                (text) in
                let newText = text?.stringByTrimmingWhitespace
                self.experiment?[rowInfo.key] = newText
                if case .title = rowInfo { self.title = newText }
                self.tableView.reloadCell(cell)
            }
            
        case .EditeTags:
            guard let etcvc = segue.destinationViewController.contentViewController as? EditeTagsCollectionViewController else { return }
            let tagsTableViewCell = sender as! TagsTableViewCell
            etcvc.tags = tagsTableViewCell.tags ?? []
            etcvc.title = tagsTableViewCell.titleLabel.text
            
            etcvc.done = {
                (tags) in
                self.experiment?.tags = tags
                self.tableView.reloadCell(tagsTableViewCell)
            }
            
        }
    }
    

    private enum SegueID: String {
        case ShowUserDetail
        case ShowReviews
        case ShowFans
        case ShowExperimentsByTag
        case EditeText
        case EditeTags
    }
    
    private enum RowInfo: String, ReusableCellInfo {
        case title
        case tags
        case creationDate
        
        case author

        case purpose
        case principle
        case content
        case steps
        case results
        
        case conclusion
        
        case footNote
        
        case reviews
        case fans
        
        var cellReuseIdentifier: String {
            switch self {
            case .title, .creationDate:
                return "RightDetailCell"
            case .tags:
                return "CollectionCell"
            case .purpose, .principle, .content, .steps, .results, .conclusion, .footNote:
                return "SubTitleCell"
            case .reviews, .fans:
                return "BasicCell"
            case .author:
                return "UserCell"
            }
        }
        
        var key: String { return rawValue }
        
        var segueID: SegueID? {
            switch self {
            case .author:
                return .ShowUserDetail
            case .reviews:
                return .ShowReviews
            case .fans:
                return .ShowFans
            default: return nil
            }
        }
        
        var segueIDWhileEditing: SegueID? {
            switch self {
            case .tags:
                return .EditeTags
            case .title, .purpose, .principle, .content, .steps, .results, .conclusion, .footNote:
                return .EditeText
            default: return nil
            }
        }
        
    }
    
}

extension ExperimentDetailViewController {
    // MARK: - Bar Button Item
    var likeBarButtonItem: SwitchBarButtonItem {
        let result = SwitchBarButtonItem(title: "", style: .Plain, target: self, action: "likeClicked:")
        result.onStateTitle = "Liking"
        result.offStateTitle = "Like"
        result.on = CKUsers.AmILikingThisExperiment(experiment!)
        return result
    }
    
    func likeClicked(sender: SwitchBarButtonItem) {
        !sender.on ? doLike(sender) : doUnlike(sender)
        sender.on = !sender.on
    }
    
    private func doLike(sender: SwitchBarButtonItem) {
        CKUsers.LikeExperiment(experiment!,
            didFail: {
                self.handleFail($0)
                sender.on = !sender.on
            }
        )
    }
    
    private func doUnlike(sender: SwitchBarButtonItem) {
        CKUsers.UnlikeExperiment(experiment!,
            didFail: {
                self.handleFail($0)
                sender.on = !sender.on
            }
        )
    }
    
    var deleteBarButtonItem: UIBarButtonItem {
        return UIBarButtonItem(title: "Delete", style: .Done, target: self, action: "deleteClicked")
    }
    
    func deleteClicked() {
        presentingViewController?.dismissViewControllerAnimated(true) { delete?(experiment!) }
    }
    
    
}

extension NSDate {
    var smartString: String {
        let absTimeIntervalSinceNow = -timeIntervalSinceNow
        switch absTimeIntervalSinceNow {
        case 0..<NSDate.OneMinute:
            return "Now"
        case NSDate.OneMinute..<NSDate.OneHour:
            // eg. 10 Minutes
            let minutes = Int(absTimeIntervalSinceNow / NSDate.OneMinute)
            return "\(minutes) minutes ago"
        case NSDate.OneHour..<NSDate.OneDay:
            // eg. 10 Hours
            let hours = Int(absTimeIntervalSinceNow / NSDate.OneHour)
            return "\(hours) hours ago"
        default:
            // eg. 10 Days
            let days = Int(absTimeIntervalSinceNow / NSDate.OneDay)
            return "\(days) days ago"
        }
    }
    
    var string: String { return NSDateFormatter.localizedStringFromDate(self, dateStyle: .MediumStyle, timeStyle: .ShortStyle) }
    
    static var OneMinute:   Double { return 60 }
    static var OneHour:     Double { return 60 * 60 }
    static var OneDay:      Double { return 24 * 60 * 60 }

}

extension String {
    var stringByTrimmingWhitespace: String { return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) }
}

