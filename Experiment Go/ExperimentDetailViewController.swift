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
        super.configureBarButtons()
        showBackwardBarButtonItemIfNeeded()
        if experiment?.createdByMe == true {
            // createdByMe
            navigationItem.rightBarButtonItem = editButtonItem()
            navigationItem.rightBarButtonItem?.enabled = shouldDone
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
        cell.setFocus(shouldFocus(rowInfo: rowInfo))
        switch rowInfo {
        case .title:
            cell.title = rowInfo.displayTitle
            cell.subTitle = experiment?.title
            cell.accessoryType = editing ? .DisclosureIndicator : .None
            
        case .creationDate:
            cell.title = rowInfo.displayTitle
            cell.subTitle = experiment?.creationDate.string
            
        case .tags:
            let collectionCell = cell as! TagsTableViewCell
            collectionCell.tags = experiment?.tags ?? []
            collectionCell.collectionView.userInteractionEnabled = editing ? false : true
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .purpose, .principle, .content, .steps, .results, .conclusion, .footNote:
            cell.title = rowInfo.displayTitle
            cell.subTitle = experiment?[key] as? String
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .reviews, .fans:
            cell.title = rowInfo.displayTitle
            
        case .author:
            let userCell = cell as! UserTableViewCell
            userCell.user = experiment?.creatorUser
        }

    }
    
    private func shouldFocus(rowInfo rowInfo: RowInfo) -> Bool {
        switch rowInfo {
        case .reviews, .fans, .author:
            return true
        default:
            return editing && RowInfo.NotOptionalRowInfos.contains(rowInfo) && String.isBlank(experiment?[rowInfo.key] as? String)
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title == "Author" ? RowInfo.author.displayTitle : nil
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
            ettvc.text = cell.subTitle?.stringByTrimmingWhitespaceAndNewline
            
            ettvc.done = {
                (text) in
                print(text)
                self.experiment?[rowInfo.key] = text?.stringByTrimmingWhitespaceAndNewline
                self.tableView.reloadCell(cell)
                self.navigationItem.rightBarButtonItem?.enabled = self.shouldDone
                if case .title = rowInfo { self.title = text?.stringByTrimmingWhitespaceAndNewline }
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
                self.navigationItem.rightBarButtonItem?.enabled = self.shouldDone
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
        
        var displayTitle: String {
            switch self {
            case .title:
                return NSLocalizedString("title", comment: "").capitalizedString
            case .tags:
                return NSLocalizedString("tags", comment: "").capitalizedString
            case .creationDate:
                return NSLocalizedString("date", comment: "").capitalizedString

            case .author:
                return NSLocalizedString("author", comment: "").capitalizedString

            case .purpose:
                return NSLocalizedString("purpose", comment: "").capitalizedString

            case .principle:
                return NSLocalizedString("principle", comment: "").capitalizedString

            case .content:
                return NSLocalizedString("content", comment: "").capitalizedString

            case .steps:
                return NSLocalizedString("steps", comment: "").capitalizedString

            case .results:
                return NSLocalizedString("results", comment: "").capitalizedString

            case .conclusion:
                return NSLocalizedString("conclusion", comment: "").capitalizedString

            case .footNote:
                return NSLocalizedString("footNote", comment: "").capitalizedString

            case .reviews:
                return NSLocalizedString("reviews", comment: "").capitalizedString

            case .fans:
                return NSLocalizedString("fans", comment: "").capitalizedString

            }
        }
    
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
        
        

        // Experiment must have value for these keys.
        static var NotOptionalRowInfos: [RowInfo] {
            return [.title, .content, .conclusion]
        }
        
//        func trimmedTextFrom(text: String?) -> String? {
//            switch self {
//            case .title:
//                return text?.stringByTrimmingWhitespaceAndNewline
//            case .purpose, .principle, .content, .steps, .results, .conclusion, .footNote:
//                return text?.stringByTrimmingWhitespaceAndNewline
//            default: abort()
//            }
//        }
    }
    
}

extension ExperimentDetailViewController {
    // MARK: - Bar Button Item
    var likeBarButtonItem: SwitchBarButtonItem {
        let result = SwitchBarButtonItem(title: "", style: .Plain, target: self, action: "likeClicked:")
        result.onStateTitle = NSLocalizedString("Liking", comment: "")
        result.offStateTitle = NSLocalizedString("Like", comment: "")
        result.on = CKUsers.AmILikingThisExperiment(experiment!)
        return result
    }
    
    func likeClicked(sender: SwitchBarButtonItem) {
        guard didAuthoriseElseRequest(didAuthorize: { self.likeClicked(sender) }) else { return }
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
        return UIBarButtonItem(title: NSLocalizedString("Delete", comment: ""), style: .Done, target: self, action: "deleteClicked")
    }
    
    func deleteClicked() {
        guard didAuthoriseElseRequest(didAuthorize: deleteClicked) else { return }
        presentingViewController?.dismissViewControllerAnimated(true) { delete?(experiment!) }
    }
    
    private var shouldDone: Bool {
        guard editing else { return true }
        var trueCount = 0
        RowInfo.NotOptionalRowInfos.forEach { if !String.isBlank(experiment?[$0.key] as? String) { trueCount++ } }
        return trueCount == RowInfo.NotOptionalRowInfos.count
    }
}

extension NSDate {
    var smartString: String {
        let absTimeIntervalSinceNow = -timeIntervalSinceNow
        switch absTimeIntervalSinceNow {
        case 0..<NSDate.OneMinute:
            return NSLocalizedString("Now", comment: "")
        case NSDate.OneMinute..<NSDate.OneHour:
            // eg. 10 Minutes
            let minutes = Int(absTimeIntervalSinceNow / NSDate.OneMinute)
            return String.localizedStringWithFormat(NSLocalizedString("%i minutes ago", comment: "") , minutes)
        case NSDate.OneHour..<NSDate.OneDay:
            // eg. 10 Hours
            let hours = Int(absTimeIntervalSinceNow / NSDate.OneHour)
            return String.localizedStringWithFormat(NSLocalizedString("%i hours ago", comment: "") , hours)
        default:
            // eg. 10 Days
            let days = Int(absTimeIntervalSinceNow / NSDate.OneDay)
            return String.localizedStringWithFormat(NSLocalizedString("%i days ago", comment: "") , days)
        }
    }
    
    var string: String { return NSDateFormatter.localizedStringFromDate(self, dateStyle: .MediumStyle, timeStyle: .ShortStyle) }
    
    static var OneMinute:   Double { return 60 }
    static var OneHour:     Double { return 60 * 60 }
    static var OneDay:      Double { return 24 * 60 * 60 }

}

extension String {
    var stringByTrimmingWhitespaceAndNewline: String { return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }

    func trimmedText(type type: TrimTextType = .Content) -> String {
        var result = self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        switch type {
        case .Title:
            result = result.stringByReplacingOccurrencesOfString("\n", withString: "")
            return result
        case .Tag:
            result = result.stringByReplacingOccurrencesOfString(" ", withString: "")
            result = result.stringByReplacingOccurrencesOfString("\n", withString: "")
            return result
        case .Content:
            return result
        }
    }
}

enum TrimTextType {
    case Title
    case Tag
    case Content
}


