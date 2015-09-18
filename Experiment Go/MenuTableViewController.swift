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
    
    var currentUser: CKRecord? { return AppDelegate.Cloud.Manager.currentUser }

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setBarSeparatorHidden(true)
        startObserve()
        updateUI()
    }
    
    // MARK: - KVO

    deinit {
        stopObserve()
    }
    
    var cuhco:  NSObjectProtocol?
    
    func startObserve() {
        cuhco =
            NSNotificationCenter.defaultCenter().addObserverForName(Notification.CurrentUserHasChange.rawValue,
                object: nil,
                queue: NSOperationQueue.mainQueue()) { (_) in self.updateUI() }
    }
    
    func stopObserve() {
        if cuhco != nil { NSNotificationCenter.defaultCenter().removeObserver(cuhco!) }
    }

    
    // MARK: - Update UI
    var profileImageURL: NSURL? {
        return (AppDelegate.Cloud.Manager.currentUser?[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
    
    
    func updateUI() {
        // Clear UI
        profileImagButton.setBackgroundImage(nil, forState: .Normal)
        
        // Reset UI
        self.title = currentUser?[UsersKey.DisplayName] as? String ?? "Menu"
        
        guard let url = profileImageURL else { profileImagButtonActivity?.stopAnimating() ; return  }
        
        UIImage.getImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.profileImagButton.setBackgroundImage($0, forState: .Normal)
            self.profileImagButtonActivity?.stopAnimating()
        }

    }
    
    private var egSplitViewController: EGSplitViewController { return splitViewController as! EGSplitViewController }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.textLabel?.text == "Profile" {
                performSegueWithIdentifier(SegueID.ShowUserDetail.rawValue, sender: cell)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            } else {
                egSplitViewController.showDetailViewControllerAtIndex(indexPath.row)
            }
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = Storyboard.TableHeaderViewDefualtHeight - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
    }
    
    // MARK: - About App Button

    @IBOutlet weak var aboutAppButton: UIButton!    {
        didSet {
            // Add border
            aboutAppButton.layer.borderColor = UIColor.whiteColor().CGColor
            aboutAppButton.layer.borderWidth = aboutAppButton.bounds.size.height / 32
            // Add corner radius
            aboutAppButton.layer.cornerRadius = aboutAppButton.bounds.size.height / 2
            aboutAppButton.layer.masksToBounds = true
            
        }
    }
    
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController else { return }
            udvc.user = AppDelegate.Cloud.Manager.currentUser
        case .ShowAppDetail:
        guard let advc = segue.destinationViewController.contentViewController as? AppDetailViewController else { return }
        guard let ppc = advc.navigationController?.popoverPresentationController else { return }
            ppc.backgroundColor = UIColor.whiteColor()
            ppc.delegate = self
        }
    }
    
    private enum SegueID: String {
        case ShowUserDetail
        case ShowAppDetail
    }
    
}

extension MenuTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let nav = controller.presentedViewController ; let advc = nav.contentViewController as! AppDetailViewController
        advc.adapted = true
        return nav
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
        let currentUser = AppDelegate.Cloud.Manager.currentUser!
        currentUser[UsersKey.ProfileImageAsset] = profileImageAsset
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


