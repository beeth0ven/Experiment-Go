//
//  UserDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/25/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

protocol CurrentUserHasChangeObserver: class {
    func startObserveCurrentUserHasChange()
    func stopObserveCurrentUserHasChange()
    func updateUI()
}

extension CurrentUserHasChangeObserver {
    func startObserveCurrentUserHasChange() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateUI",
            name: Notification.currentUserHasChange.rawValue,
            object: nil
        )
    }
    func stopObserveCurrentUserHasChange() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

class UserDetailViewController: ItemDetailViewController, CurrentUserHasChangeObserver {
    
    var user: CKUsers? {
        get { return item as? CKUsers }
        set { item = newValue ; if newValue?.isMe == true { startObserveCurrentUserHasChange() } }
    }
    
    // MARK: - Key Value Observe
    deinit { if user?.isMe == true { stopObserveCurrentUserHasChange() } }
    
    func updateUI() {
        // Clear UI
        title = user?.displayTitle
        tableView.updateVisibleCells()
    }
    
    override func configureBarButtons() {
        showBackwardBarButtonItemIfNeeded()
        if user?.isMe == true {
            navigationItem.rightBarButtonItem = editButtonItem()
            toolbarItems = nil
            if editing { navigationItem.hideLeftBarButtonItems() }
        } else {
            toolbarItems = [followBarButtonItem]
        }
    }
    
    override func configureCell(cell: UITableViewCell, forKey key: String) {
        let rowInfo = RowInfo(rawValue: key)!
        switch rowInfo {
        case .profileImageAsset:
            let imageTableViewCell = cell as! ImageTableViewCell
            imageTableViewCell.profileImageURL = user?.profileImageAsset?.fileURL
            cell.accessoryType = editing ? .DisclosureIndicator : .None
            
        case .displayName:
            cell.title = "Display Name"
            cell.subTitle = user?.displayName
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .aboutMe:
            cell.title = "About me"
            cell.subTitle = user?.aboutMe
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .posted, .liked, .following, .follower:
            cell.title = key.capitalizedString
            
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
            ditvc.title = "Profile Image"
            ditvc.image = imageTableViewCell.profileImge
            
            ditvc.done = {
                image in
                let imageData = UIImageJPEGRepresentation(image, 0.1)!
                let profileImageAsset = CKAsset(data: imageData)
                self.user?.profileImageAsset = profileImageAsset
                self.tableView.reloadCell(imageTableViewCell)
            }
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let indexPath = tableView.indexPathForCell(cell)! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.title = cell.title
            ettvc.text = cell.subTitle?.stringByTrimmingWhitespace
            
            ettvc.done = {
                (text) in
                let newText = text?.stringByTrimmingWhitespace
                if case .displayName = rowInfo {
                    self.user?.displayName = newText
                    self.title = newText
                } else if case .aboutMe = rowInfo {
                    self.user?.aboutMe = newText
                }
                self.tableView.reloadCell(cell)
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
        result.onStateTitle = "Following"
        result.offStateTitle = "Follow"
        result.on = CKUsers.AmIFollowingTo(user!)
        return result
    }
    
    func followClicked(sender: SwitchBarButtonItem) {
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

}
