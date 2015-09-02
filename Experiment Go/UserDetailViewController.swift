//
//  UserDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import UIKit
import CloudKit



class UserDetailViewController: RecordDetailViewController {

    // MARK: - Properties
    
    var user: CKRecord? {
        get { return record }
        set { record = newValue ;
            title = newValue?[UserKey.DisplayName] as? String
        }
    }
    
    // MARK: - View Configure

    @IBOutlet var followBarButtonItem: SwitchBarButtonItem!
    
    
    override func configureBarButtons() {
        super.configureBarButtons()
        switch editeState {
        case .New:
            break
            
        case .Read:
            showCloseBarButtonItemIfNeeded()
            if imCreator {
                navigationItem.rightBarButtonItems = [editButtonItem()]
                toolbarItems = nil
            } else {
                navigationItem.rightBarButtonItems = nil
                self.followBarButtonItem.on = AppDelegate.Cloud.Manager.amIFollowingTheUser(user!)
            }
            
        case .Write:
            navigationItem.leftItemsSupplementBackButton = false
            navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: UIView())]
            navigationItem.rightBarButtonItems = [editButtonItem()]
        }
        
    }
    
    
    
    // MARK: - @IBAction
    
    @IBAction func toggleFollowState(sender: SwitchBarButtonItem) {
        let unFollow = !sender.on
        if unFollow {
            doFollow()
        } else {
            doUnFollow()
        }
    }
    
    private func doFollow() {
        self.setToolbarItems([activityBarButtonItem], animated: true)
        AppDelegate.Cloud.Manager.followUser(user!) {
            (error) in
            self.setToolbarItems([self.followBarButtonItem], animated: true)
            guard error == nil else { print(error!.localizedDescription) ; return }
            self.followBarButtonItem.on = true
        }
    }
    
    private func doUnFollow() {
        self.setToolbarItems([activityBarButtonItem], animated: true)
        AppDelegate.Cloud.Manager.unfollowUser(user!) {
            (error) in
            self.setToolbarItems([self.followBarButtonItem], animated: true)
            guard error == nil else { print(error!.localizedDescription) ; return }
            self.followBarButtonItem.on = false
        }
        
    }
    

    
    // MARK: - Table View Data Struct
    
    private enum RowInfo: ReusableCellInfo {
        case Basic(key:String)
        case SubTitle(key:String)
        case Image(key:String)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return "BasicCell"
            case .SubTitle(_):
                return "SubTitleCell"
            case .Image(_):
                return "ImageCell"
            }
        }
        
        var key: String? {
            switch self {
            case .Basic(let key):
                return key
            case .SubTitle(let key):
                return key
            case .Image(let key):
                return key
            }
        }
        
    }

    override func setupSections() -> [SectionInfo] {
        guard user != nil else { return [SectionInfo]() }
        
        var result = [SectionInfo]()
        // Sections 1: OverView
        let imageRow: RowInfo = .Image(key: UserKey.ProfileImageAsset)
        let aboutMeRow: RowInfo = .SubTitle(key: UserKey.AboutMe)
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: [imageRow, aboutMeRow])
        result.append(overViewSectionInfo)
        
        // Sections 2: Experiments
        if editing == false {
            let postedExperimentsRow: RowInfo = .Basic(key: "Posted Experiments")
            let likedExperimentRow: RowInfo = .Basic(key: "Liked Experiments")
            let experimentsSectionInfo = SectionInfo(title: "Experiments", rows: [postedExperimentsRow, likedExperimentRow])
            result.append(experimentsSectionInfo)
        }
        
        // Sections 3: Relationship
        if editing == false {
            let follwingRow: RowInfo = .Basic(key: "Following")
            let followerRow: RowInfo = .Basic(key: "Follower")
            let relationshipSectionInfo = SectionInfo(title: "Relationship", rows: [follwingRow, followerRow])
            result.append(relationshipSectionInfo)
        }
        return result
    }
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        super.configureCell(cell, atIndexPath: indexPath)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        switch rowInfo {
        case .Basic(let key):
            cell.textLabel!.text = key
        case .SubTitle(let key):
            guard let subTitleCell = cell as? SubTitleTableViewCell else { return }
            subTitleCell.titleLabel.text = "About me:"
            let text = (user?[key] as? CustomStringConvertible)?.description
            subTitleCell.subTttleLabel.text = text ?? "Not Set"
            subTitleCell.accessoryType = editing ? .DisclosureIndicator : .None
        case .Image(let key):
            guard let imageCell = cell as? ImageTableViewCell else { return }
            imageCell.profileImageURL = (user?[key] as? CKAsset)?.fileURL
            cell.accessoryType = editing ? .DisclosureIndicator : .None
        }
    }
    
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let segueID = segueIDAtIndexPath(indexPath) else { return }
        switch segueID {
        case .EditeImage:
            let ipc = UIImagePickerController()
            ipc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            ipc.allowsEditing = true
            ipc.delegate = self
            presentViewController(ipc, animated: true, completion: nil)
            
        default:
            performSegueWithIdentifier(segueID.rawValue, sender: tableView.cellForRowAtIndexPath(indexPath))
        }
       
    }
    
    private func segueIDAtIndexPath(indexPath: NSIndexPath) -> SegueID? {
        guard let rowInfo = sections[indexPath.section].rows[indexPath.row] as? RowInfo else { return nil }
        switch rowInfo {
        case .Basic(let key):
            return segueIDByKey[key]
            
        case .SubTitle(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        case .Image(let key):
            guard editing else { return nil }
            return segueIDByKey[key]
            
        }
    }
    
    private var segueIDByKey: [String: SegueID] {
        return [
            "Posted Experiments":       .ShowPostedExperiments,
            "Liked Experiments":        .ShowLikedExperiments,
            "Following":                .ShowFollowingUsers,
            "Follower":                 .ShowFollower,
            UserKey.AboutMe:            .EditeText,
            UserKey.ProfileImageAsset:  .EditeImage
        ]
    }
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {

        case .EditeText:
            guard let ettvc = segue.destinationViewController.contentViewController as? EditeTextTableViewController else { return }
            let indexPath = tableView.indexPathForCell((sender as! UITableViewCell))! ; let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
            ettvc.text = user![rowInfo.key!] as? String
            ettvc.title = "About me"
            
            ettvc.doneBlock = {
                self.user![rowInfo.key!] = ettvc.text;
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        case .ShowPostedExperiments:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.title = (sender as! UITableViewCell).textLabel?.text
            rtvc.queryPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user!.recordID)
            
        case .ShowLikedExperiments:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.title = (sender as! UITableViewCell).textLabel?.text
            rtvc.recordType = RecordType.Link.rawValue
            let userPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user!.recordID)
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserLikeExperiment.rawValue)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
            rtvc.fetchType = FetchedRecordsController.FetchType.LinkIncludeDestinationAndDestinationCreatorUser.rawValue
            
        case .ShowFollowingUsers:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.title = (sender as! UITableViewCell).textLabel?.text
            let userPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user!.recordID)
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserFollowUser.rawValue)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [userPredicate, typePredicate])
            rtvc.fetchType = FetchedRecordsController.FetchType.LinkIncludeDestination.rawValue

        case .ShowFollower:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.title = (sender as! UITableViewCell).textLabel?.text
            let toPredicate = NSPredicate(format: "%K = %@", LinkKey.To, user!)
            let typePredicate = NSPredicate(format: "%K = %@", LinkKey.LinkType ,LinkType.UserFollowUser.rawValue)
            rtvc.queryPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [toPredicate, typePredicate])

        default: break
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

}

extension UserDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBAction func changeProfileImage(sender: UIButton) {
        let ipc = UIImagePickerController()
        ipc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        ipc.allowsEditing = true
        ipc.delegate = self
        presentViewController(ipc, animated: true, completion: nil)
    }
    
    
    // MARK: - Image Picker Controller Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as! UIImage
//        let imageData = UIImageJPEGRepresentation(image, 0.2)!
//        let profileImageAsset = CKAsset(data: imageData)
//        let currentUser = AppDelegate.Cache.Manager.currentUser()!
//        currentUser[UserKey.ProfileImageAsset] = profileImageAsset
//        self.profileImagButtonActivity?.startAnimating()
//        AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(currentUser) { (_, error) in
//            guard error == nil else { print(error!.localizedDescription) ; abort() }
//            dispatch_async(dispatch_get_main_queue()) {
//                self.updateUI()
//            }
//        }
//        self.dismissViewControllerAnimated(true) {
//            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
//        }
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
        }
    }
}
