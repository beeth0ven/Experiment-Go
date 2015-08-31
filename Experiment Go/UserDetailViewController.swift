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
        set { record = newValue ; title = newValue?[UserKey.DisplayName] as? String }
    }
    
    @IBOutlet var followBarButtonItem: SwitchBarButtonItem! {
        didSet {
            followBarButtonItem.offStateTitle = "Follow"
            followBarButtonItem.onStateTitle = "Following"
        }
    }
    
    
    override func configureBarButtons() {
        super.configureBarButtons()
        switch editeState {
        case .New:
            break
            
        case .Read:
            if closeBarButtonItem != nil { navigationItem.leftBarButtonItems = [closeBarButtonItem!] }
            if imCreator {
                navigationItem.rightBarButtonItems = [editButtonItem()]
                toolbarItems = nil
            } else {
                navigationItem.rightBarButtonItems = nil
//                toolbarItems = [activityBarButtonItem]
//                AppDelegate.Cloud.Manager.amILikingThisExperiment(experiment!) {
//                    (liking)  in
//                    self.likeBarButtonItem.on = liking
//                    self.setToolbarItems([self.likeBarButtonItem], animated: true)
//                }
            }
            
        case .Write:
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = [editButtonItem()]
        }
        
    }
    
    
    // MARK: - Table View Data Struct
    
    private enum RowInfo: ReusableCellInfo {
        case Basic(String)
        case SubTitle(String, String?)
        case Image(NSURL)
        
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
        
        var segueIdentifier: String? {
            guard case .Basic(let text) = self else { return nil }
            switch text {
            case "Posted Experiments":
                return SegueID.ShowPostedExperiments.rawValue
            case "Liked Experiments":
                return SegueID.ShowLikedExperiments.rawValue
            default: return nil
            }
        }
    }
    
    override func setupSections() -> [SectionInfo] {
        var result = [SectionInfo]()
        // Sections 1: OverView
        let imageRow: RowInfo = .Image((user![UserKey.ProfileImageAsset] as! CKAsset).fileURL)
        let descriptionRow: RowInfo = .SubTitle(UserKey.Description.capitalizedString,user?[UserKey.Description] as? String)
        let overViewSectionInfo = SectionInfo(title: "OverView", rows: [imageRow, descriptionRow])
        result.append(overViewSectionInfo)
        
        // Sections 2: Experiments
        if editing == false {
            let postedExperimentsRow: RowInfo = .Basic("Posted Experiments")
            let likedExperimentRow: RowInfo = .Basic("Liked Experiments")
            let experimentsSectionInfo = SectionInfo(title: "Experiments", rows: [postedExperimentsRow, likedExperimentRow])
            result.append(experimentsSectionInfo)
        }
        
        // Sections 3: Relationship
        if editing == false {
            let follwingRow: RowInfo = .Basic("Following")
            let followerRow: RowInfo = .Basic("Follower")
            let relationshipSectionInfo = SectionInfo(title: "Relationship", rows: [follwingRow, followerRow])
            result.append(relationshipSectionInfo)
        }
        return result
    }
    
    override func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        super.configureCell(cell, atIndexPath: indexPath)
        let rowInfo = sections[indexPath.section].rows[indexPath.row] as! RowInfo
        switch rowInfo {
        case .Basic(let text):
            cell.textLabel!.text = text
        case .SubTitle(let text, let detailText):
            cell.textLabel!.text = text
            cell.detailTextLabel!.text = detailText ?? "Not Set."
        case .Image(let url):
            guard let imageCell = cell as? ImageTableViewCell else { return }
            imageCell.profileImageURL = url
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowPostedExperiments:
            guard let rtvc = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            rtvc.queryPredicate = NSPredicate(format: "%K = %@", RecordKey.CreatorUserRecordID, user!.recordID)
            rtvc.navigationItem.rightBarButtonItem = nil
            rtvc.navigationItem.leftBarButtonItem = nil
            rtvc.showRecordModelly = false
        case .ShowLikedExperiments:
//            guard let ftvc = segue.destinationViewController.contentViewController as? FansTableViewController else { return }
//            ftvc.likedExperiment = experiment
            break
        }
    }
    
    private enum SegueID: String {
        case ShowPostedExperiments
        case ShowLikedExperiments
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
