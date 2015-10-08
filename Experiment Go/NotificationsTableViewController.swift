//
//  NotificationsTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

class NotificationsTableViewController: CloudKitTableViewController {
    

    override var refreshOperation: GetCKItemsOperation {
        return GetNotificationLinksOperation()
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return GetNotificationLinksOperation(type: .GetNextPage(cursor))
    }
    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReusableIdentifierAtIndexPath(indexPath), forIndexPath: indexPath) as! CKItemTableViewCell
        cell.item = items[indexPath.section][indexPath.row]
        return cell
    }
    
    @IBInspectable
    var followCellReusableIdentifier: String?
    @IBInspectable
    var fanCellReusableIdentifier: String?
    @IBInspectable
    var reviewCellReusableIdentifier: String?
    
    func cellReusableIdentifierAtIndexPath(indexPath: NSIndexPath) -> String {
        let link = items[indexPath.section][indexPath.row] as! CKLink
        switch link.type! {
        case .UserFollowUser:
            return followCellReusableIdentifier!
        case .UserLikeExperiment:
            return fanCellReusableIdentifier!
        case .UserReviewToExperiment:
            return reviewCellReusableIdentifier!
        }
    }
    
    
    // MARK: - Segue
    
    @IBAction func showExperiment(sender: UIButton) { performSegueWithIdentifier(SegueID.ShowExperiment.rawValue, sender: sender) }
    @IBAction func showUserDetail(sender: UIButton) { performSegueWithIdentifier(SegueID.ShowUserDetail.rawValue, sender: sender) }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        guard let segueID = SegueID(rawValue: identifier) else { return }
        switch segueID {
        case .ShowExperiment:
            guard let edvc = segue.destinationViewController.contentViewController as? ExperimentDetailViewController,
                let cell = UITableViewCell.cellForView(sender as! UIButton) as? LinkTableViewCell else { return }
            edvc.experiment = cell.link?.experiment
            
        case .ShowUserDetail:
            guard let udvc = segue.destinationViewController.contentViewController as? UserDetailViewController,
                let cell = UITableViewCell.cellForView(sender as! UIButton) as? LinkTableViewCell else { return }
            udvc.user = cell.link?.creatorUser

        case .ShowFollower:
            guard let utvc = segue.destinationViewController.contentViewController as? UsersTableViewController else { return }
            utvc.title = "Follower".localizedString
            utvc.queryType = .FollowerFrom(CKUsers.CurrentUser!)
            
        case .ShowFans:
            guard let utvc = segue.destinationViewController.contentViewController as? UsersTableViewController,
                let cell = sender as? LinkTableViewCell else { return }
            utvc.queryType = .FansBy(cell.link!.experiment!)

        case .ShowReviews:
            guard let rtvc = segue.destinationViewController.contentViewController as? ReviewsTableViewController,
                let cell = sender as? LinkTableViewCell else { return }
            rtvc.reviewTo = cell.link?.experiment

        }
    }
    
    
    private enum SegueID: String {
        case ShowExperiment
        case ShowUserDetail
        case ShowFollower
        case ShowFans
        case ShowReviews
    }
}