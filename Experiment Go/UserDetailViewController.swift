//
//  UserDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import UIKit
import CoreData



class UserDetailViewController: DetailViewController {
    
    private enum Segue: String {
        case ShowUserDetail = "showUserDetail"
        case ShowExperimentDetail = "showExperimentDetail"
        
    }
    
    // MARK: - Properties
    
    var user: User? {
        get {
            return detailItem as? User
        }
        
        set {
            detailItem = newValue
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideBarSeparator()
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let controller = segue.destinationViewController as? DetailViewController else { return }
        guard let cell = sender as? RootObjectTableViewCell else { return }
        controller.detailItem = cell.detailItem!
    }
    
    // MARK: - Table View Data Source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedInfoController.sections[section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        switch sectionUnique {
        case .PostedExperiments, .LikedExperiments, .FollowingUsers, .Followers, .PostedReviews:
            guard relationshipSetForSectionUnique(sectionUnique)!.count == 0 else { fallthrough }
            return 1
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        switch sectionUnique {
        case .PostedExperiments, .LikedExperiments, .FollowingUsers, .Followers, .PostedReviews:
            guard indexPath.row == relationshipSetForSectionUnique(sectionUnique)!.count else { fallthrough }
            return tableView.dequeueReusableCellWithIdentifier(Storyboard.EmptyStyleCellReuseIdentifier, forIndexPath: indexPath)
        default:
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedInfoController.sections[section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        return sectionUnique.name
    }
    
    private func relationshipSetForSectionUnique(sectionUnique :SectionUnique) -> NSMutableSet? {
        let sectionInfo = sectionInfoForIdentifier(sectionUnique.rawValue)
        guard case .ToManyRelationship(let key,_) = sectionInfo.style else { return nil }
        return detailItem?.mutableSetValueForKey(key)
    }
    
    // MARK: - Fetched Info Controller Data Source
    
    override func identifiersForSectionInfos() -> [String] {
        return SectionUnique.allValues
    }
    
    override func sectionInfoForIdentifier(identifier: String) -> SectionInfo {
        let style: SectionInfo.Style!
        let editingStyles: [SectionInfo.EditingStyle] = []
        let sectionUnique = SectionUnique(rawValue: identifier)!
        switch sectionUnique {
        case .OverView:
            style = .Attribute
        case .PostedExperiments:
            style = .ToManyRelationship(identifier , > )
        case .LikedExperiments:
            style = .ToManyRelationship(identifier , > )
        case .FollowingUsers:
            style = .ToManyRelationship(identifier , > )
        case .Followers:
            style = .ToManyRelationship(identifier , > )
        case .PostedReviews:
            style = .ToManyRelationship(identifier , > )
        }
        
        return SectionInfo(identifier: identifier, style: style, editingStyles: editingStyles)
        
    }
    
    
    
    override func cellKeysBySectionInfo(sectionInfo: SectionInfo) -> [String]? {
        
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        
        guard case .OverView = sectionUnique  else { return nil }
        
        return [
            User.Constants.ProfileImageDataKey,
            User.Constants.NameKey,
            User.Constants.EmailKey,
            RootObject.Constants.CreateDateKey
        ]
        
    }
    
    
    override func cellReuseIdentifierFromItemKey(key: String) -> String? {
        switch key {
        case User.Constants.ProfileImageDataKey:
            return Storyboard.ImageCellReuseIdentifier
            
        case User.Constants.NameKey:
            return Storyboard.TextCellReuseIdentifier
            
        case User.Constants.EmailKey:
            return Storyboard.TextCellReuseIdentifier
            
            
            
        case SectionUnique.PostedExperiments.rawValue:
            return Storyboard.ExperimentCellReuseIdentifier
            
        case SectionUnique.LikedExperiments.rawValue:
            return Storyboard.ExperimentCellReuseIdentifier
            
            
        case SectionUnique.FollowingUsers.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        case SectionUnique.Followers.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        default: return super.cellReuseIdentifierFromItemKey(key)
        }
    }
    
    // MARK: - Section Construct
    
    private enum SectionUnique: String {
        case OverView = "overView"
        case PostedExperiments = "postedExperiments"
        case LikedExperiments = "likedExperiments"
        case FollowingUsers = "followingUsers"
        case Followers = "followers"
        case PostedReviews = "postedReviews"
        
        static var allValues: [String] {
            return [
                SectionUnique.OverView.rawValue,
                SectionUnique.PostedExperiments.rawValue,
                SectionUnique.LikedExperiments.rawValue,
                SectionUnique.FollowingUsers.rawValue,
                SectionUnique.Followers.rawValue,
                SectionUnique.PostedReviews.rawValue,
            ]
        }
        
        var name: String? {
            switch self {
            case .OverView:
                return nil
            case .PostedExperiments:
                return "Posted Experiments"
            case .LikedExperiments:
                return "Liked Experiments"
            case .FollowingUsers:
                return "Following"
            case .Followers:
                return "Followers"
            case .PostedReviews:
                return "Posted Reviews"
            }
        }
    }
}

extension DetailViewController.Storyboard {
    static let ExperimentCellReuseIdentifier = "ExperimentCell"

}