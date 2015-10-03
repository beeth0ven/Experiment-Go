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
    
    @IBInspectable
    var followUserCellReusableIdentifier: String?

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifierAtIndexPath(indexPath), forIndexPath: indexPath) as! CKItemTableViewCell
        cell.item = items[indexPath.section][indexPath.row]
        if let followUserTableViewCell = cell as? FollowUserTableViewCell { followUserTableViewCell.handleFail = handleFail }
        return cell
    }
    
    
    func cellReusableIdentifierAtIndexPath(indexPath: NSIndexPath) -> String {
        if case .FollowingFrom(let user) = queryType! {
            if user.isMe { return followUserCellReusableIdentifier! }
        }
        return cellReusableIdentifier!
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