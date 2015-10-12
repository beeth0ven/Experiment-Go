//
//  UserDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/25/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit


class UserDetailViewController: ItemDetailViewController, CurrentUserHasChangeObserver {
    
    var user: CKUsers? {
        get { return item as? CKUsers }
        set { item = newValue ; if newValue?.isMe == true { startObserveCurrentUserHasChange() } }
    }
    
    // MARK: - Key Value Observe
    deinit { if user?.isMe == true { stopObserve() } }
    
    func updateUI() {
        // Clear UI
        title = user?.displayTitle
        tableView.updateVisibleCells()
    }
    
    override func configureBarButtons() {
        super.configureBarButtons()
        showBackwardBarButtonItemIfNeeded()
        if user?.isMe == true {
            navigationItem.rightBarButtonItem = editButtonItem()
            navigationItem.rightBarButtonItem?.enabled = shouldDone
            toolbarItems = nil
            if editing { navigationItem.hideLeftBarButtonItems() }

        } else {
            toolbarItems = [followBarButtonItem]
        }
    }
    
    override func configureCell(cell: UITableViewCell, forKey key: String) {
        let rowInfo = RowInfo(rawValue: key)!
        cell.setFocus(shouldFocus(rowInfo: rowInfo))
        switch rowInfo {
        case .profileImageAsset:
            let imageTableViewCell = cell as! ImageTableViewCell
            imageTableViewCell.profileImageURL = user?.profileImageAsset?.fileURL
            cell.accessoryType = editing ? .DisclosureIndicator : .None
            
        case .displayName:
            cell.title = rowInfo.displayTitle
            cell.subTitle = user?.displayName
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .aboutMe:
            cell.title = rowInfo.displayTitle
            cell.subTitle = user?.aboutMe
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .posted, .liked, .following, .follower:
            cell.title = rowInfo.displayTitle
            
        }
    }
    
    private func shouldFocus(rowInfo rowInfo: RowInfo) -> Bool {
        switch rowInfo {
        case .posted, .liked, .following, .follower:
            return true
        default:
            return editing && RowInfo.NotOptionalRowInfos.contains(rowInfo) && String.isBlank(user?[rowInfo.key] as? String)
        }
    }
    

    override func setupSections() -> [SectionInfo] {
        let infos = !editing ? sectionInfos : sectionInfosWhileEditing
        return  infos.map { SectionInfo(title: $0.title, rows: $0.reusableCellInfos) }
    }
    
    private var sectionInfos: [(title: String, reusableCellInfos: [ReusableCellInfo])] {
        return allSectionInfos.map { (title: $0.title, reusableCellInfos: $0.reusableCellInfos.filter { !(RowInfo.aboutMe.rawValue == $0.key && String.isBlank(self.user?.aboutMe)) }) }
    }
    
    private var sectionInfosWhileEditing: [(title: String, reusableCellInfos: [ReusableCellInfo])] {
        return allSectionInfos.filter {  ["Experiments", "Relationship"].contains($0.title) == false }
    }
    
    private var allSectionInfos: [(title: String, reusableCellInfos: [ReusableCellInfo])] = [
        
        ("OverView", [
            RowInfo.profileImageAsset,
            RowInfo.displayName,
            RowInfo.aboutMe
            ]
        ),
        
        ("Experiments",[
            RowInfo.posted,
            RowInfo.liked,
            ]
        ),
        
        ("Relationship",[
            RowInfo.following,
            RowInfo.follower
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

    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        let cell = sender as! UITableViewCell
        switch segueID {
        case .EditeImage:
            guard let ditvc = segue.destinationViewController.contentViewController as? EditeImageTableViewController else { return }
            let imageTableViewCell = cell as! ImageTableViewCell
            ditvc.title = NSLocalizedString("Profile Image", comment: "")
            ditvc.image = imageTableViewCell.profileImge
            
            ditvc.done = {
                image in
                let squreImage = image.squreImageWithWidth(256)
                let imageData = UIImageJPEGRepresentation(squreImage, 1.0)!
                let sizeString = NSByteCountFormatter.stringFromByteCount(Int64(imageData.length), countStyle: NSByteCountFormatterCountStyle.File)
                print("imageData size: \(sizeString)")
                let profileImageAsset = CKAsset(data: imageData)
                self.user?.profileImageAsset = profileImageAsset
                self.tableView.reloadCell(imageTableViewCell)
                self.navigationItem.rightBarButtonItem?.enabled = self.shouldDone
            }
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let indexPath = tableView.indexPathForCell(cell)! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.title = cell.title
            ettvc.text = cell.subTitle?.stringByTrimmingWhitespaceAndNewline
            
            ettvc.done = {
                (text) in
                let trimmedText = text?.stringByTrimmingWhitespaceAndNewline
                if case .displayName = rowInfo {
                    self.user?.displayName = trimmedText
                    self.title = text
                } else if case .aboutMe = rowInfo {
                    self.user?.aboutMe = trimmedText
                }
                self.tableView.reloadCell(cell)
                self.navigationItem.rightBarButtonItem?.enabled = self.shouldDone
            }
            
        case .ShowPostedExperiments:
            guard let etvc = segue.destinationViewController.contentViewController as? ExperimentsTableViewController else { return }
            etvc.title = cell.title
            etvc.queryType = .PostedBy(user!)
            
        case .ShowLikedExperiments:
            guard let etvc = segue.destinationViewController.contentViewController as? ExperimentsTableViewController else { return }
            etvc.title = cell.title
            etvc.queryType = .LikedBy(user!)
            
        case .ShowFollowingUsers:
            guard let utvc = segue.destinationViewController.contentViewController as? UsersTableViewController else { return }
            utvc.title = cell.title
            utvc.queryType = .FollowingFrom(user!)

        case .ShowFollower:
            guard let utvc = segue.destinationViewController.contentViewController as? UsersTableViewController else { return }
            utvc.title = cell.title
            utvc.queryType = .FollowerFrom(user!)
            

        }
        
        
    }

    private enum SegueID: String {
        case EditeImage
        case EditeText
        case ShowPostedExperiments
        case ShowLikedExperiments
        case ShowFollowingUsers
        case ShowFollower
        
    }
    
    private enum RowInfo: String, ReusableCellInfo {
        
        case profileImageAsset
        case displayName
        case aboutMe
        
        case posted
        case liked
        
        case following
        case follower
        
        var cellReuseIdentifier: String {
            switch self {
            case .profileImageAsset:
                return "ImageCell"
            case .displayName:
                return "RightDetailCell"
            case .aboutMe:
                return "SubTitleCell"
            case .posted, .liked, .following, .follower:
                return "BasicCell"
            }
        }
        
        var key: String { return rawValue }
        
        var displayTitle: String {
            switch self {
            case .profileImageAsset:
                return NSLocalizedString("ProfileImageAsset", comment: "")
            case .displayName:
                return NSLocalizedString("Display Name", comment: "")
            case .aboutMe:
                return NSLocalizedString("About me", comment: "")
                
            case .posted:
                return NSLocalizedString("Posted", comment: "")
                
            case .liked:
                return NSLocalizedString("Liked", comment: "")
                
            case .following:
                return NSLocalizedString("Following", comment: "")
                
            case .follower:
                return NSLocalizedString("Follower", comment: "")
            }
        }
        
        var segueID: SegueID? {
            switch self {
            case .posted:
                return .ShowPostedExperiments
            case .liked:
                return .ShowLikedExperiments
            case .following:
                return .ShowFollowingUsers
            case .follower:
                return .ShowFollower
            default: return nil
            }
        }
        
        var segueIDWhileEditing: SegueID? {
            switch self {
            case .profileImageAsset:
                return .EditeImage
            case .displayName, .aboutMe:
                return .EditeText
            default: return nil
            }
        }
        
        // Experiment must have value for these keys.
        static var NotOptionalRowInfos: [RowInfo] {
            return [.displayName]
        }
        
    }

}

extension UITableView {
    func reloadCell(cell: UITableViewCell) {
        guard let indexPath = indexPathForCell(cell) else { return }
        reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
}

extension UserDetailViewController {
    // MARK: - Bar Button Item
    var followBarButtonItem: SwitchBarButtonItem {
        let result = SwitchBarButtonItem(title: "", style: .Plain, target: self, action: "followClicked:")
        result.onStateTitle = NSLocalizedString("Following", comment: "")
        result.offStateTitle = NSLocalizedString("Follow", comment: "")
        result.on = CKUsers.AmIFollowingTo(user!)
        return result
    }
    
    func followClicked(sender: SwitchBarButtonItem) {
        guard didAuthoriseElseRequest(didAuthorize: { self.followClicked(sender) }) else { return }
        !sender.on ? doFollow(sender) : doUnfollow(sender)
        sender.on = !sender.on
    }
    
    private func doFollow(sender: SwitchBarButtonItem) {
        CKUsers.FollowUser(user!,
            didFail: {
                self.handleFail($0)
                sender.on = !sender.on
            }
        )
    }
    
    private func doUnfollow(sender: SwitchBarButtonItem) {
        CKUsers.UnfollowUser(user!,
            didFail: {
                self.handleFail($0)
                sender.on = !sender.on
            }
        )
        
    }
    
    private var shouldDone: Bool {
        guard editing else { return true }
        var trueCount = 0
        RowInfo.NotOptionalRowInfos.forEach { if !String.isBlank(user?[$0.key] as? String) { trueCount++ } }
        return trueCount == RowInfo.NotOptionalRowInfos.count
    }

}

extension UIImage {
    func squreImageWithWidth(width: CGFloat) -> UIImage {
        let imageView = UIImageView(frame: CGRect(origin: CGPointZero, size: CGSize(width: width, height: width)))
        imageView.contentMode = .ScaleAspectFill
        imageView.image = self
        UIGraphicsBeginImageContext(imageView.frame.size)
        imageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension UINavigationItem {
    func hideLeftBarButtonItems() {
        leftItemsSupplementBackButton = false
        leftBarButtonItems = [UIBarButtonItem(customView: UIView())]
    }
}

extension UITableViewCell {
    var title: String? {
        get { return textLabel?.text }
        set { textLabel?.text = newValue }
    }
    
    var subTitle: String? {
        get { return detailTextLabel?.text }
        set { detailTextLabel?.text = newValue }
    }
    
    func setFocus(focus: Bool) {
        textLabel?.textColor = focus ? DefaultStyleController.Color.Sand : UIColor.blackColor()
    }
}

extension SubTitleTableViewCell {
    override var title: String? {
        get { return titleLabel?.text }
        set { titleLabel?.text = String.isBlank(newValue) ? " " : newValue }
    }
    
    override var subTitle: String? {
        get { return subTttleLabel?.text }
        set { subTttleLabel?.text = String.isBlank(newValue) ? " " : newValue  }
    }
    
    override func setFocus(focus: Bool) {
        titleLabel?.textColor = focus ? DefaultStyleController.Color.DarkSand : UIColor.blackColor()
    }
}


