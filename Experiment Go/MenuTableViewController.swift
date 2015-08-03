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
        static let TableHeaderViewDefualtHeight: CGFloat = 136
    }

    private enum Segue: String {
        case ShowUserDetail = "showUserDetail"
    }
    
    @IBOutlet weak var tableHeaderContentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var profileImagView: UIImageView! {
        didSet {
            profileImagView.layer.borderColor = UIColor.whiteColor().CGColor
            profileImagView.layer.borderWidth = profileImagView.bounds.size.height / 32
        }
    }
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = Storyboard.TableHeaderViewDefualtHeight - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
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
            if cell.textLabel?.text == "Profile" {
                performSegueWithIdentifier("showUserDetail", sender: cell)
            } else {
                performSegueWithIdentifier("showMaster", sender: cell)
            }
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
    
    @IBAction func closeToMenu(segue: UIStoryboardSegue) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}

