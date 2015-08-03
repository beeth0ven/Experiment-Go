//
//  ExperimentDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import UIKit
import CoreData



class ExperimentDetailViewController: DetailViewController {
    
    private enum SegueID: String {
        case ShowUserDetail
        case AddNewReview
    }

    
    // MARK: - Properties

    var experiment: Experiment? {
        get {
            return detailItem as? Experiment
        }
        
        set {
            detailItem = newValue
        }
    }
    

    @IBOutlet weak var likeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideBarSeparator()
    }
    
     override func configureBarButtons() {
        if detailItem.inserted {
            self.editing = true
            navigationItem.leftBarButtonItems = [cancelBarButtonItem]
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            
        } else {
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
            navigationItem.rightBarButtonItems = [editButtonItem()]
            
        }
        super.configureBarButtons()
    }

    
    // MARK: - User Actions
    
    @IBAction func toggleLikeStates(sender: UIBarButtonItem) {
        var success = false
        if sender.title == "Like" {
            // Do like
            success = doLike()
        } else if sender.title == "Liking" {
            // Do UnLike
            success = doUnLike()
        }
        
        if success {
            sender.title = (sender.title == "Like") ? "Liking" : "Like"
        }
    }
    
    
    private func doLike() -> Bool {
        let sectionUnique = SectionUnique.UsersLikeMe
        let user = User.currentUser()
        let usersLikeMe = relationshipSetForSectionUnique(sectionUnique)!
        guard usersLikeMe.containsObject(User.currentUser()) == false else { return false }
        usersLikeMe.addObject(user)
        let usersLikeMeAsArray = relationshipArrayForSectionUnique(sectionUnique)!
        guard
            let row: Int = usersLikeMeAsArray.indexOf(user),
            let section: Int = identifiersForSectionInfos().indexOf(sectionUnique.rawValue)
            else { return false }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        tableView.beginUpdates()
        if usersLikeMe.count == 1 {
            // Empty Cell Change to Normal Cell
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        tableView.endUpdates()
        return true
    }


    private func doUnLike() -> Bool  {
        let sectionUnique = SectionUnique.UsersLikeMe
        let user = User.currentUser()
        let usersLikeMe = relationshipSetForSectionUnique(sectionUnique)!
        guard usersLikeMe.containsObject(User.currentUser()) == true else { return false }
        let usersLikeMeAsArray = relationshipArrayForSectionUnique(sectionUnique)!
        guard
            let row: Int = usersLikeMeAsArray.indexOf(user),
            let section: Int = identifiersForSectionInfos().indexOf(sectionUnique.rawValue)
            else { return false }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        usersLikeMe.removeObject(user)
        tableView.beginUpdates()
        if usersLikeMe.count == 0 {
            // Normal Cell Change to Empty Cell
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        tableView.endUpdates()
        return true
    }
    // MARK: - View Configure
    
    override func updateUI() {
        super.updateUI()
        let usersLikeMe = relationshipSetForSectionUnique(.UsersLikeMe)!
        likeBarButtonItem?.title = usersLikeMe.containsObject(User.currentUser()) ? "Liking" : "Like"
    }
    // MARK: - Help Method

    private func relationshipSetForSectionUnique(sectionUnique :SectionUnique) -> NSMutableSet? {
        let sectionInfo = sectionInfoForIdentifier(sectionUnique.rawValue)
        guard case .ToManyRelationship(let key,_) = sectionInfo.style else { return nil }
        return detailItem?.mutableSetValueForKey(key)
    }
    
    private func relationshipArrayForSectionUnique(sectionUnique :SectionUnique) -> [RootObject]? {
        let sectionInfo = sectionInfoForIdentifier(sectionUnique.rawValue)
        guard case .ToManyRelationship(let key, let isOrderedBefore) = sectionInfo.style else { return nil }
        return (experiment?.mutableSetValueForKey(key).allObjects as? [RootObject])?.sort(isOrderedBefore)
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier != nil else { return }
        guard let segueID = SegueID(rawValue: segue.identifier!) else { return }
        switch segueID {
        case .ShowUserDetail:
            let controller = segue.destinationViewController as! DetailViewController
            if let cell = sender as? RootObjectTableViewCell {
                controller.detailItem = cell.detailItem!
            }
        case .AddNewReview:
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! ReviewViewController
            let review = RootObject.insertNewObjectForEntityForName(Review.Constants.EntityNameKey) as! Review
            controller.review = review
        }

    }
    
    // MARK: - Table View Data Source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedInfoController.sections[section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        switch sectionUnique {
        case .Reviews, .UsersLikeMe:
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
        case .Reviews, .UsersLikeMe:
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
        case .WhoPost:
            style = .ToOneRelationship(identifier)
        case .Reviews:
            style = .ToManyRelationship(identifier , > )
        case .UsersLikeMe:
            style = .ToManyRelationship(identifier , > )
        }
        
        return SectionInfo(identifier: identifier, style: style, editingStyles: editingStyles)
        
    }
    
    
    
    override func cellKeysBySectionInfo(sectionInfo: SectionInfo) -> [String]? {
        
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        
        guard case .OverView = sectionUnique  else { return nil }
        
        return [
            Experiment.Constants.TitleKey,
            Experiment.Constants.BodyKey,
            RootObject.Constants.CreateDateKey
        ]
        
    }
    
    
    override func cellReuseIdentifierFromItemKey(key: String) -> String? {
        switch key {
        case SectionUnique.WhoPost.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        case SectionUnique.Reviews.rawValue:
            return Storyboard.ReviewCellReuseIdentifier

        case SectionUnique.UsersLikeMe.rawValue:
            return Storyboard.UserCellReuseIdentifier
            
        default: return super.cellReuseIdentifierFromItemKey(key)
        }
    }
    
    // MARK: - Section Construct

    private enum SectionUnique: String {
        case OverView = "overView"
        case WhoPost = "whoPost"
        case Reviews = "reviews"
        case UsersLikeMe = "usersLikeMe"
        
        static var allValues: [String] {
            return [
                SectionUnique.OverView.rawValue,
                SectionUnique.WhoPost.rawValue,
                SectionUnique.Reviews.rawValue,
                SectionUnique.UsersLikeMe.rawValue,
            ]
        }
        
        var name: String? {
            switch self {
            case .OverView:
                return nil
            case .WhoPost:
                return "Author"
            case .Reviews:
                return "Reviews"
            case .UsersLikeMe:
                return "Who Like Me"
            }
        }
    }
    
}

extension DetailViewController.Storyboard {
    static let EmptyStyleCellReuseIdentifier = "EmptyStyleCell"
    static let UserCellReuseIdentifier = "UserCell"
    static let ReviewCellReuseIdentifier = "ReviewCell"
}


extension ExperimentDetailViewController {
    // MARK: - Unwind Segue
    @IBAction func cancelToExperimentDetail(segue: UIStoryboardSegue) {
        guard let dvc = segue.sourceViewController as? DetailViewController else { return }
        if dvc.detailItem!.inserted {
            NSManagedObjectContext.defaultContext().deleteObject(dvc.detailItem!)
        }
    }
    
    @IBAction func saveToExperimentDetail(segue: UIStoryboardSegue) {
        if let rvc = segue.sourceViewController as? ReviewViewController {
            let review = rvc.review!
            review.body = rvc.bodyTextView.text
            let sectionUnique = SectionUnique.Reviews
            let reviewSet = relationshipSetForSectionUnique(sectionUnique)!
            reviewSet.addObject(review)
            let reviews = relationshipArrayForSectionUnique(sectionUnique)!
            let row: Int = reviews.indexOf(review)!
            let section: Int = identifiersForSectionInfos().indexOf(sectionUnique.rawValue)!
            let indexPath = NSIndexPath(forRow: row, inSection: section)
            
            tableView.beginUpdates()
            if reviews.count == 1 {
                // Empty Cell Change to Normal Cell
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            } else {
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            tableView.endUpdates()
        }
        
        NSManagedObjectContext.saveDefaultContext()
    }
    
    @IBAction func closeToExperimentDetail(segue: UIStoryboardSegue) {
    }
    
}

