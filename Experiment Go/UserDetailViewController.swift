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
        case ShowUserDetail
        case ShowExperimentDetail
        
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
    
    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var recommendBarButtonItem: SwitchBarButtonItem!
    @IBOutlet var followBarButtonItem: SwitchBarButtonItem! {
        didSet {
            followBarButtonItem.offStateTitle = "Follow"
            followBarButtonItem.onStateTitle = "Following"
        }
    }
    
    @IBOutlet var flexibleSpaceBarButtonItem: UIBarButtonItem!
    
    var detailItemShowStyle: DetailItemShowStyle {
        
        let imTheUser = user == User.currentUser()
        let isRootViewController = navigationController?.viewControllers.first == self
        guard isRootViewController else { return .PublicRead }

        if imTheUser && editing == false {
            return .AuthorRead
        } else if imTheUser && editing == true {
            return .AuthorModify
        } else {
            return .PublicRead
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideBarSeparator()
    }
    
    // MARK: - User Actions
    
    
    @IBAction func toggleFollowStates(sender: SwitchBarButtonItem) {
        let success = (sender.on == false) ? doFollow() : doUnFollow()
        if success { sender.on = !sender.on }
    }
    
    
    private func doFollow() -> Bool {
        return addObject(User.currentUser(), forToManyRelationshipKey: SectionUnique.Followers.rawValue)
    }
    
    
    private func doUnFollow() -> Bool  {
        return removeObject(User.currentUser(), forToManyRelationshipKey: SectionUnique.Followers.rawValue)
    }
    
    // MARK: - View Configure
    
    override func configureBarButtons() {
        
        switch detailItemShowStyle {
        case .AuthorRead:
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [recommendBarButtonItem]
        case .AuthorModify:
            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [recommendBarButtonItem]
        case .PublicRead:
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
            navigationItem.rightBarButtonItems = []
            guard user != User.currentUser() else { toolbarItems = [recommendBarButtonItem] ; break }
            toolbarItems = [recommendBarButtonItem, flexibleSpaceBarButtonItem, followBarButtonItem]
        default: break
        }
        
        // If self is in a navigation stack then change leftBarButton to navigation default back button.
        // Call super's configureBarButtons will finish the task.
        super.configureBarButtons()
    }
    
    override func updateUI() {
        super.updateUI()
        let followerSet = detailItem!.mutableSetValueForKey(SectionUnique.Followers.rawValue)
        followBarButtonItem.on = followerSet.containsObject(User.currentUser())
    }
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let controller = segue.destinationViewController as? DetailViewController else { return }
        guard let cell = sender as? RootObjectTableViewCell else { return }
        controller.detailItem = cell.detailItem!
    }
    
    // MARK: - Table View Data Source
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedInfoController.sections[section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        return sectionUnique.name
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
        case .Followers:
            style = .ToManyRelationship(identifier , > )
        case .FollowingUsers:
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
            return MasterViewController.Storyboard.ExperimentCellReuseIdentifier
            
        case SectionUnique.LikedExperiments.rawValue:
            return MasterViewController.Storyboard.ExperimentCellReuseIdentifier
            
            
        case SectionUnique.Followers.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        case SectionUnique.FollowingUsers.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        default: return super.cellReuseIdentifierFromItemKey(key)
        }
    }
    
    // MARK: - Section Construct
    
    private enum SectionUnique: String {
        case OverView = "overView"
        case PostedExperiments = "postedExperiments"
        case LikedExperiments = "likedExperiments"
        case Followers = "followers"
        case FollowingUsers = "followingUsers"
        
        static var allValues: [String] {
            return [
                SectionUnique.OverView.rawValue,
                SectionUnique.PostedExperiments.rawValue,
                SectionUnique.LikedExperiments.rawValue,
                SectionUnique.Followers.rawValue,
                SectionUnique.FollowingUsers.rawValue,
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
            case .Followers:
                return "Followers"
            case .FollowingUsers:
                return "Following"
            }
        }
    }
}
