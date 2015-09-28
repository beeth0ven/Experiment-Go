//
//  MenuTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class MenuTableViewController: UITableViewController, CurrentUserHasChangeObserver {

    @IBOutlet weak var tableHeaderContentViewHeightConstraint: NSLayoutConstraint! {
        didSet { tableHeaderViewDefualtHeight = tableHeaderContentViewHeightConstraint.constant }
    }
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            // Add border
            profileImageView.layer.borderColor = UIColor.whiteColor().CGColor
            profileImageView.layer.borderWidth = profileImageView.bounds.size.height / 32
            // Add corner radius
            profileImageView.layer.cornerRadius = profileImageView.bounds.size.height / 2
            profileImageView.layer.masksToBounds = true
            
        }
    }
    
    var profileImage: UIImage? {
        get { return profileImageView.image }
        set { profileImageView.image = newValue }
    }
    
    var currentUser: CKUsers? { return CKUsers.currentUser }
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setBarSeparatorHidden(true)
        startObserveCurrentUserHasChange()
        updateUI()
    }
    
    deinit { stopObserveCurrentUserHasChange() }
    
    // MARK: - Update UI
    var profileImageURL: NSURL? {
        return currentUser?.profileImageAsset?.fileURL
    }
    
    
    func updateUI() {
        // Clear UI
        profileImage = nil
        self.title = currentUser?.displayName ?? "Menu"
        guard let url = profileImageURL else { return  }
        UIImage.getImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.profileImage = $0
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
        let height = tableHeaderViewDefualtHeight! - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
    }
    
    private var tableHeaderViewDefualtHeight: CGFloat?

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
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController else { abort() }
            udvc.user = CKUsers.currentUser
            
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



