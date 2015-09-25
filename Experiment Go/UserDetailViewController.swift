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

class UserDetailViewController: ObjectDetailViewController, CurrentUserHasChangeObserver {
    
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
        showCloseBarButtonItemIfNeeded()
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
            cell.textLabel?.text = "Display Name"
            cell.detailTextLabel?.text = user?.displayName ?? " "
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .aboutMe:
            let subTitleTableViewCell = cell as! SubTitleTableViewCell
            subTitleTableViewCell.titleLabel.text = "About me"
            subTitleTableViewCell.subTttleLabel.text = user?.aboutMe ?? " "
            cell.accessoryType = editing ? .DisclosureIndicator : .None

        case .posted, .liked, .following, .follower:
            cell.textLabel?.text = key.capitalizedString
            
        }
    }
    
    override func setupSections() -> [SectionInfo] {
        let infos = !editing ? sectionInfos : sectionInfosWhileEditing
        return  infos.map { SectionInfo(title: $0.title, rows: $0.reusableCellInfos) }
    }
    
    private var sectionInfos: [(title: String, reusableCellInfos: [ReusableCellInfo])] {
        return allSectionInfos
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
            if case .EditeImage = segueID { changeProfileImageFromSender(tableView.cellForRowAtIndexPath(indexPath)!) ; return }
            performSegueWithIdentifier(segueID.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        }
    }

    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
            
        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let cell = sender as! UITableViewCell
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

            default: break
        }
        
        
    }
    
    
    private func changeProfileImageFromSender(sender: UITableViewCell) {
        
        let ipc = ImagePickerController(
            done: {
                image in
                let imageData = UIImageJPEGRepresentation(image, 0.5)!
                let profileImageAsset = CKAsset(data: imageData)
                self.user?.profileImageAsset = profileImageAsset
                self.tableView.reloadCell(sender)
            }
        )
        
        presentViewController(ipc, animated: true, completion: nil)
       
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
        result.on = false
        return result
    }
    
    func follewClicked(sender: SwitchBarButtonItem) {
        
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
