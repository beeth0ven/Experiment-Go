//
//  MenuTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class MenuTableViewController: UITableViewController {
    
    private struct Storyboard {
        static let ProfileImagViewDefualtHeight: CGFloat = 96
    }

    private enum Segue: String {
        case ShowUserDetail = "showUserDetail"
    }
    
    @IBOutlet weak var profileImagView: UIImageView! {
        didSet {
            profileImagView.layer.borderColor = UIColor.whiteColor().CGColor
            profileImagView.layer.borderWidth = profileImagView.bounds.size.height / 32
        }
    }

    @IBOutlet weak var profileImagViewHeightConstraint: NSLayoutConstraint!
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = Storyboard.ProfileImagViewDefualtHeight - scrollView.contentOffset.y
        profileImagViewHeightConstraint.constant = height > 0 ? height : 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.title = User.currentUser().name
        profileImagView.image = User.currentUser().profileImage ?? UIImage.defultTestImage()
        hideBarSeparator()
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            guard cell.textLabel?.text != "Profile" else { return }
            performSegueWithIdentifier("showMaster", sender: cell)
        }
    }

    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMaster" {
            if let controller = (segue.destinationViewController as! UINavigationController).topViewController as? MasterViewController {
                if let cell = sender as? UITableViewCell {
                    if  let text = cell.textLabel?.text {
                        controller.title = text
                        
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                        controller.navigationItem.leftItemsSupplementBackButton = true
                        self.splitViewController?.toggleMasterView()
                    }
                }
            }
        } else if segue.identifier == Segue.ShowUserDetail.rawValue {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = User.currentUser()
        }
    }


}


extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem()
        UIApplication.sharedApplication().sendAction(barButtonItem.action,
            to: barButtonItem.target,
            from: barButtonItem,
            forEvent: nil
        )
    }
}
