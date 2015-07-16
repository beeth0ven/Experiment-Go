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
    
//    var managedObjectContext: NSManagedObjectContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false

    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            performSegueWithIdentifier("showMaster", sender: cell)
        }
    }

    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMaster" {
            if let controller = (segue.destinationViewController as! UINavigationController).topViewController as? MasterViewController {
                if let cell = sender as? UITableViewCell {
                    if  let text = cell.textLabel?.text {
//                        controller.managedObjectContext = managedObjectContext
                        controller.title = text
                        
                        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                        controller.navigationItem.leftItemsSupplementBackButton = true
                        self.splitViewController?.toggleMasterView()
                    }
                }
            }
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
