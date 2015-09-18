//
//  WelcomeToCloudTVC.swift
//  Experiment Go
//
//  Created by luojie on 9/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class WelcomeToCloudTVC: UITableViewController {

    
    private var progressState: ProgressState {
        print(NSFileManager.defaultManager().ubiquityIdentityToken)
        guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return .Account }
        guard hasCloudWritePermision == true else { return .Permison }
        guard (AppDelegate.Cloud.Manager.currentUser?[UsersKey.DisplayName] as? String) != nil else { return .DisplayName }
        return .Done
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        startObserve()
        showCloseBarButtonItemIfNeeded()
        setBarSeparatorHidden(true)
    }

    var authorized: (() -> Void)?
    
    func updateUI() {
        for cell in tableView.visibleCells { self.configureCell(cell, atIndexPath: tableView.indexPathForCell(cell)!) }
        if case .Done = progressState {
            startButton.enabled = true
            startButton.backgroundColor = DefaultStyleController.Color.DarkSand
        } else {
            startButton.enabled = false
            startButton.backgroundColor = UIColor.lightGrayColor()
        }
    }
    
    @IBOutlet weak var startButton: UIButton!
    @IBAction func start(sender: UIButton) {  presentingViewController?.dismissViewControllerAnimated(true, completion: authorized) }
    

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return super.numberOfSectionsInTableView(tableView)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    

    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let cellRepresentProgressState = ProgressState(rawValue: indexPath.row) else { return }
        cell.accessoryView = nil
        guard cellRepresentProgressState == progressState else {
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.selectionStyle = .None
            cell.accessoryType = progressState.hashValue > cellRepresentProgressState.hashValue ? .Checkmark : .None
            return
        }
        cell.textLabel?.textColor = DefaultStyleController.Color.DarkSand
        cell.selectionStyle = .Default
        cell.accessoryType = .None
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let cellRepresentProgressState = ProgressState(rawValue: indexPath.row) else { return }
//        guard cellRepresentProgressState == progressState else { return }
        switch cellRepresentProgressState {
        case .Account:
            showSignIntoiCloudAlert()
        case .Permison:
            requestPermission(tableView.cellForRowAtIndexPath(indexPath)!)
        case .DisplayName:
            doSetUserDisplayName(tableView.cellForRowAtIndexPath(indexPath)!)
        default: break
        }
    }
    
    private func showSignIntoiCloudAlert() {
        let alert = UIAlertController(errorMessage: "Please sign into an iCloud account on current device from iOS setting App.")
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func failed(error: NSError) { updateUI() ; handleFailed(error) }
    
    private func requestPermission(sender: UITableViewCell) {
        sender.accessoryView = UIActivityIndicatorView.defaultView()
        cloudManager.getDiscoverabilityPermission(
            didGet:{
                (success) in
                sender.accessoryView = nil
                self.hasCloudWritePermision = success
                self.updateUI()
                if !success { self.showPermissonAuthorizationFailedAlert() }
            },
            
            failed: failed
        )
    }
    
    private func showPermissonAuthorizationFailedAlert() {
        let alert = UIAlertController(errorMessage: "Authorization failed.\nYou can still get permision from the path bellow later:\n iOS Setting -> iCLoud -> iCloud Drive -> Look Me Up By Email.")
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

    private func doSetUserDisplayName(sender: UITableViewCell) {
        getUserDisplayName(
            didGet: {
                guard let name = $0 else { return }
                sender.accessoryView = UIActivityIndicatorView.defaultView()
                self.cloudManager.setUserDisplayName(name,
                    didSet: {  self.updateUI() },
                    failed: self.failed)
            }
        )
    }
    
    private func getUserDisplayName(didGet didGet: (String?) -> ()) {
        let alert = UIAlertController(title: "Experiment Go", message: "Please set a display name which can never be changed.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (_)  in didGet(nil) }))
        alert.addAction(UIAlertAction(
            title: "Use Forever",
            style: .Default)
            { (_)  in
                guard let textField = alert.textFields?.first else { return }
                didGet(textField.text)
            }
            
        )
        
        alert.addTextFieldWithConfigurationHandler { (textField) in textField.placeholder = "Display Name" }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private var cloudManager: CloudManager { return AppDelegate.Cloud.Manager }

    
    // MARK: - KVO
    

    deinit { stopObserve()  }
    
    var uidcno:  NSObjectProtocol?
    
    func startObserve() {
        uidcno =
            NSNotificationCenter.defaultCenter().addObserverForName(NSUbiquityIdentityDidChangeNotification,
                object:nil,
                queue: NSOperationQueue.mainQueue()) { (_) in
                    self.updateUI()
        }
        
    }
    
    func stopObserve() {
        if uidcno != nil { NSNotificationCenter.defaultCenter().removeObserver(uidcno!) }
    }

    // MARK: - Preferred Setting

    override var preferredContentSize: CGSize {
        get { return CGSize(width: 480, height: 550)  }
        set { super.preferredContentSize = newValue }
    }
    
    
    
    private enum ProgressState: Int {
        case Account = 0
        case Permison = 1
        case DisplayName = 2
        case Done = 3
    }
    

}


extension UIViewController {
    var hasCloudWritePermision: Bool? {
        get { return AppDelegate.Cloud.Manager.hasCloudWritePermision }
        set { AppDelegate.Cloud.Manager.hasCloudWritePermision = newValue }
    }
    
    func presentWelcomeToCloudTVC(authorized authorized: ((Void) -> Void)?) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let welcomeToCloudNav = storyboard.instantiateViewControllerWithIdentifier("WelcomeToCloudNav")
        (welcomeToCloudNav.contentViewController as! WelcomeToCloudTVC).authorized = authorized
        presentViewController(welcomeToCloudNav, animated: true, completion: nil)
    }
}