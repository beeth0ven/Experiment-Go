//
//  MenuTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class MenuTableViewController: UITableViewController {
    
    private struct Storyboard {
        static let TableHeaderViewDefualtHeight: CGFloat = 150
    }
  
    @IBOutlet weak var tableHeaderContentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var profileImagButton: UIButton!  {
        didSet {
            // Add border
            profileImagButton.layer.borderColor = UIColor.whiteColor().CGColor
            profileImagButton.layer.borderWidth = profileImagButton.bounds.size.height / 32
            // Add corner radius
            profileImagButton.layer.cornerRadius = profileImagButton.bounds.size.height / 2
            profileImagButton.layer.masksToBounds = true
            
        }
    }
    
    @IBOutlet weak var profileImagButtonActivity: UIActivityIndicatorView!
    

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setBarSeparatorHidden(true)
        updateCurrentUser()

    }

    
    // MARK: - Update UI
    var profileImageURL: NSURL? {
        return (AppDelegate.Cache.Manager.currentUser()?[UserKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
    
    func updateUI() {
        // Clear UI
        profileImagButton.setBackgroundImage(nil, forState: .Normal)
        
        // Reset UI
        let currentUser = AppDelegate.Cache.Manager.currentUser()
        self.title = currentUser?[UserKey.DisplayName] as? String
        
        guard let url = profileImageURL else { profileImagButtonActivity?.stopAnimating() ; return  }
        
        UIImage.fetchImageForURL(url) { (image) in
            guard url == self.profileImageURL else { return }
            self.profileImagButton.setBackgroundImage(image, forState: .Normal)
            self.profileImagButtonActivity?.stopAnimating()
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.textLabel?.text == "Profile" {
                performSegueWithIdentifier(SegueID.ShowUserDetail.rawValue, sender: cell)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            } else {
                performSegueWithIdentifier(SegueID.ShowExperiments.rawValue, sender: cell)
            }
        }
    }
    
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = Storyboard.TableHeaderViewDefualtHeight - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
    }
    
    // MARK: - Update Current User

    
    private func updateCurrentUser() {
        AppDelegate.Cloud.Manager.updateCurrentUser() { (_) in self.updateUI() }
    }
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowExperiments:
            guard let controller = segue.destinationViewController.contentViewController as? RecordsTableViewController else { return }
            guard let cell = sender as? UITableViewCell else { return }
            guard let  text = cell.textLabel?.text else { return }
            controller.title = text
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
            self.splitViewController?.toggleMasterView()

            
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController else { return }
            udvc.user = AppDelegate.Cache.Manager.currentUser()
        }
    }
    
    private enum SegueID: String {
        case ShowExperiments
        case ShowUserDetail
    }
    
}

extension MenuTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBAction func changeProfileImage(sender: UIButton) {
        let ipc = UIImagePickerController()
        ipc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        ipc.allowsEditing = true
        ipc.delegate = self
        presentViewController(ipc, animated: true, completion: nil)
    }
    

    // MARK: - Image Picker Controller Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as! UIImage
        let imageData = UIImageJPEGRepresentation(image, 0.2)!
        let profileImageAsset = CKAsset(data: imageData)
        let currentUser = AppDelegate.Cache.Manager.currentUser()!
        currentUser[UserKey.ProfileImageAsset] = profileImageAsset
        self.profileImagButtonActivity?.startAnimating()
        AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(currentUser) { (_, error) in
            guard error == nil else { print(error!.localizedDescription) ; abort() }
            dispatch_async(dispatch_get_main_queue()) {
                self.updateUI()
            }
        }
        self.dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
        }
        
    }
    
        func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
        }
    }
}


