//
//  UsersTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class UsersTableViewController: CloudKitTableViewController {
    
    var queryType: QueryType?

    override var refreshOperation: GetCKItemsOperation {
        switch queryType!{
        case .FansBy(let experiment):
            return GetExperimentFansOperation(to: experiment)
        case .FollowingFrom(let user):
            return GetFollowingUsersOperation(followingUsersFrom: user)
        case .FollowerFrom(let user):
            return GetFollowersOperation(followersFrom: user)
        }
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        switch queryType!{
        case .FansBy(_):
            return GetExperimentFansOperation(type: .GetNextPage(cursor))
        case .FollowingFrom(_):
            return GetFollowingUsersOperation(type: .GetNextPage(cursor))
        case .FollowerFrom(_):
            return GetFollowersOperation(type: .GetNextPage(cursor))
        }        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if followingFromMe { navigationItem.rightBarButtonItem = addBarButtonItem }
    }
    
    @IBInspectable
    var followUserCellReusableIdentifier: String?

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifierAtIndexPath(indexPath), forIndexPath: indexPath) as! CKItemTableViewCell
        cell.item = items[indexPath.section][indexPath.row]
        if let followUserTableViewCell = cell as? FollowUserTableViewCell {
            followUserTableViewCell.handleFail = handleFail
            followUserTableViewCell.didAuthoriseElseRequest = didAuthoriseElseRequest
        }
        return cell
    }
    
    
    func cellReusableIdentifierAtIndexPath(indexPath: NSIndexPath) -> String {
        return followingFromMe ? followUserCellReusableIdentifier! : cellReusableIdentifier!
    }
    
    private var followingFromMe: Bool {
        guard let queryType = queryType else { return false }
        guard case .FollowingFrom(let user) = queryType else { return false }
        return user.isMe
    }
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController,
                let cell = sender as? UserTableViewCell else { return }
            udvc.user = cell.user
        }
    }
    
    
    private enum SegueID: String {
        case ShowUserDetail
    }
    
    enum QueryType {
        case FansBy(CKExperiment)
        case FollowingFrom(CKUsers)
        case FollowerFrom(CKUsers)

    }
}

extension UsersTableViewController {
    // MARK: - Bar Button Item
    var addBarButtonItem: UIBarButtonItem { return UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addClicked:") }
    
    func addClicked(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        alert.addAction( UIAlertAction( title: NSLocalizedString("Show a user by Email", comment: "") , style: .Default, handler: { _ in self.doShowUserByEmail() } ) )
        alert.addAction( UIAlertAction( title: NSLocalizedString("Show users from contacts", comment: ""), style: .Default, handler: { _ in self.doShowFromContacts() } ) )
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        alert.modalPresentationStyle = .Popover
        let ppc = alert.popoverPresentationController
        ppc?.barButtonItem = sender
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func doShowUserByEmail() {
        let alert = UIAlertController(title: NSLocalizedString("Experiment Go", comment: "") , message: NSLocalizedString("Please Enter a Email Address.", comment: "") , preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "") , style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Done", comment: ""),
            style: .Default)
            { (_)  in
                guard let textField = alert.textFields?.first else { return }
                guard let emailAddress = textField.text else { return }
                self.loading = true
                CKUsers.GetUser(email: emailAddress,
                    didGet: {
                        self.loading = false
                        guard !self.allUsersIncludeMeReocrdIDNames.contains($0.recordIDName) else { return }
                        self.items.append([$0])
                        self.tableView.appendASection()
                    },
                    didFail: {
                        self.loading = false
                        self.handleFail($0)
                    }
                )

            }
            
        )
        
        alert.addTextFieldWithConfigurationHandler {
            $0.placeholder = "username@company.com"
            $0.keyboardType = .EmailAddress
        }
        presentViewController(alert, animated: true, completion: nil)

    }
    
    func doShowFromContacts() {
        self.loading = true
        
        CKUsers.GetUsersFromContacts(
            didGet: {
                self.loading = false
                let usersToAdd = $0.filter{ !self.allUsersIncludeMeReocrdIDNames.contains($0.recordIDName) }
                guard usersToAdd.count > 0 else { return }
                self.items.append(usersToAdd)
                self.tableView.appendASection()
            },
            didFail: {
                self.loading = false
                self.handleFail($0)
            }
        )
    }
    
    private var allUsersIncludeMeReocrdIDNames: [String] {
        return CKUsers.CurrentUser == nil ? allUsersReocrdIDNames : allUsersReocrdIDNames + [CKUsers.CurrentUser!.recordIDName]
    }
    
    private var allUsersReocrdIDNames: [String] {
        return items.reduce([], combine: +).map { $0.recordIDName }
    }
}