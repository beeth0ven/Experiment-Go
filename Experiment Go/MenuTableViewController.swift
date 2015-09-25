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
        profileImagButton.setBackgroundImage(nil, forState: .Normal)
        self.title = currentUser?.displayName ?? "Menu"
        guard let url = profileImageURL else { return  }
        UIImage.getImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.profileImagButton.setBackgroundImage($0, forState: .Normal)
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



