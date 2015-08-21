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

    private enum Segue: String {
        case ShowUserDetail = "showUserDetail"
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
        self.clearsSelectionOnViewWillAppear = false
        updateUI()
        hideBarSeparator()
        startObserve()

    }
    
    deinit {
        stopObserve()
    }
    
    @IBAction func changeProfileImage(sender: UIButton) {
        let ipc = UIImagePickerController()
        ipc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        ipc.allowsEditing = true
        ipc.delegate = self
        presentViewController(ipc, animated: true, completion: nil)
    }
    

    
    // MARK: - Key Value Observe

    func startObserve() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateUI",
            name: CloudManager.Notification.CurrentUserDidChange,
            object: nil)
    }
    
    func stopObserve() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - Update UI
    @objc func updateUI() {
        // Clear UI
        profileImagButton.setBackgroundImage(nil, forState: .Normal)
        
        // Reset UI
        self.title = currentUser?.valueForKey(UserKey.DisplayName) as? String
        guard let imageData = (currentUser?.valueForKey(UserKey.ProfileImageAsset) as? CKAsset)?.data else { return }
        profileImagButton.setBackgroundImage(UIImage(data: imageData), forState: .Normal)
        profileImagButtonActivity?.stopAnimating()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if cell.textLabel?.text == "Profile" {
                performSegueWithIdentifier("showUserDetail", sender: cell)
            } else {
                performSegueWithIdentifier("showMaster", sender: cell)
            }
        }
    }
    
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = Storyboard.TableHeaderViewDefualtHeight - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
    }
    
    
    // MARK: - Segues
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showMaster" {
//            if let controller = (segue.destinationViewController as! UINavigationController).topViewController as? MasterViewController {
//                if let cell = sender as? UITableViewCell {
//                    if  let text = cell.textLabel?.text {
//                        controller.title = text
//                        
//                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
//                        controller.navigationItem.leftItemsSupplementBackButton = true
//                        self.splitViewController?.toggleMasterView()
//                    }
//                }
//            }
//        } else if segue.identifier == Segue.ShowUserDetail.rawValue {
////            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
////                controller.detailItem = User.currentUser()
//        }
//    }
    
//    @IBAction func closeToMenu(segue: UIStoryboardSegue) {
//        dismissViewControllerAnimated(true, completion: nil)
//    }

}

extension MenuTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
        // MARK: - Image Picker Controller Delegate
        func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as! UIImage
            let imageData = UIImageJPEGRepresentation(image, 0.2)!
            let profileImageAsset = CKAsset(data: imageData)
            currentUser![UserKey.ProfileImageAsset] = profileImageAsset
            publicCloudDatabase.saveRecord(currentUser!) { (_, error) in
                guard error == nil else { print(error!.localizedDescription) ; abort() }
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateUI()
                    NSNotificationCenter.defaultCenter().postNotificationName(CloudManager.Notification.CurrentUserDidChange, object: nil)
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


