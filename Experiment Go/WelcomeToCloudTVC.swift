//
//  WelcomeToCloudTVC.swift
//  Experiment Go
//
//  Created by luojie on 9/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class WelcomeToCloudTVC: UITableViewController, iCloudKeyValueStoreHasChangeObserver {
    
    private var progressState: ProgressState {
        guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return .Account }  // Login iCloud
        guard CKUsers.UserDiscoverability == true else { return .Permison }                         // Request Permision
        guard !String.isBlank(CKUsers.CurrentUser?.displayName) else { return .DisplayName }        // Set Display Name
        return .Done                                                                                // All Done
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        startObserveiCloudKeyValueStoreHasChange()
        setBarSeparatorHidden(true)
        configureBarButtons()
    }
    
    var didAuthorize: (() -> Void)?
    
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
    
    func configureBarButtons() {
        navigationItem.leftBarButtonItem = closeBarButtonItem
    }
    
    @IBOutlet weak var startButton: UIButton!
    @IBAction func start(sender: UIButton) {  presentingViewController?.dismissViewControllerAnimated(true, completion: didAuthorize) }
    
    
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
            cell.userInteractionEnabled = false
            cell.accessoryType = progressState.hashValue > cellRepresentProgressState.hashValue ? .Checkmark : .None
            return
        }
        cell.textLabel?.textColor = DefaultStyleController.Color.DarkSand
        cell.userInteractionEnabled = true
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
        let alert = UIAlertController(errorMessage: NSLocalizedString("Please sign into an iCloud account on current device from iOS setting App.", comment: "") )
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func handleFail(error: NSError) { updateUI() ; super.handleFail(error) }
    
    private func requestPermission(sender: UITableViewCell) {
        sender.accessoryView = UIActivityIndicatorView.defaultView()
        CKUsers.GetDiscoverabilityPermission(
            didGet:{
                (success) in
                sender.accessoryView = nil
                self.updateUI()
                if !success { self.showPermissonAuthorizationFailedAlert() }
            },
            
            didFail: handleFail
        )
    }
    
    private func showPermissonAuthorizationFailedAlert() {
        let alert = UIAlertController(errorMessage: NSLocalizedString("Authorization failed.\nYou can still get permision from the path bellow later:\n iOS Setting -> iCLoud -> iCloud Drive -> Look Me Up By Email.", comment: "") )
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    private func doSetUserDisplayName(sender: UITableViewCell) {
        getUserDisplayName(
            didGet: {
                guard !String.isBlank($0) else { return }
                sender.accessoryView = UIActivityIndicatorView.defaultView()
                CKUsers.SetUserDisplayName($0!, didSet: self.updateUI, didFail: self.handleFail)
            }
        )
    }
    
    private func getUserDisplayName(didGet didGet: (String?) -> ()) {
        let alert = UIAlertController(title: NSLocalizedString("Experiment Go", comment: "") , message: NSLocalizedString("Please set a display name.", comment: "") , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "") , style: .Cancel, handler: { (_)  in didGet(nil) }))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Done", comment: "") ,
            style: .Default)
            { (_)  in
                guard let textField = alert.textFields?.first else { return }
                didGet(textField.text?.stringByTrimmingWhitespaceAndNewline)
            }
            
        )
        
        alert.addTextFieldWithConfigurationHandler { (textField) in textField.placeholder = NSLocalizedString("Display Name", comment: "")  }
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - KVO
    
    func iCloudKeyValueStoreHasChange(notification: NSNotification) { self.updateUI() }
    deinit { stopObserve()  }
    
    
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}


extension UIViewController {
    func didAuthoriseElseRequest(didAuthorize didAuthorize: ((Void) -> Void)?) -> Bool {
        guard CKUsers.HasCloudWritePermision == true else {
            presentWelcomeToCloudTVC(didAuthorize: didAuthorize)
            return false
        }
        return true
    }
    
    private func presentWelcomeToCloudTVC(didAuthorize didAuthorize: ((Void) -> Void)?) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let welcomeToCloudNav = storyboard.instantiateViewControllerWithIdentifier("WelcomeToCloudNav")
        welcomeToCloudNav.modalPresentationStyle = presentingViewController == nil ? .FormSheet : .CurrentContext
        (welcomeToCloudNav.contentViewController as! WelcomeToCloudTVC).didAuthorize = didAuthorize
        presentViewController(welcomeToCloudNav, animated: true, completion: nil)
    }
}