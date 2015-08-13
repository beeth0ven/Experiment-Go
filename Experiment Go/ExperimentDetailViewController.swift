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

    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet var saveBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var addNewReviewBarButtonItem: UIBarButtonItem!
    @IBOutlet var likeBarButtonItem: SwitchBarButtonItem! {
        didSet {
            likeBarButtonItem.offStateTitle = "Like"
            likeBarButtonItem.onStateTitle = "Liking"
        }
    }
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var flexibleSpaceBarButtonItem: UIBarButtonItem!

     var detailItemShowStyle: DetailItemShowStyle {
        
        let imAuthor = self.experiment!.whoPost == User.currentUser()
        
        if  imAuthor && self.experiment!.inserted {
            return .AuthorInsert
        } else if imAuthor && editing == false {
            return .AuthorRead
        } else if imAuthor && editing == true {
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
    

    @IBAction func toggleLikeStates(sender: SwitchBarButtonItem) {
        let success = (sender.on == false) ? doLike() : doUnLike()
        if success { sender.on = !sender.on }
    }
    
    
    private func doLike() -> Bool {
        return addObject(User.currentUser(), forToManyRelationshipKey: SectionUnique.UsersLikeMe.rawValue)
    }


    private func doUnLike() -> Bool  {
        return removeObject(User.currentUser(), forToManyRelationshipKey: SectionUnique.UsersLikeMe.rawValue)
    }
    
    // MARK: - View Configure
    
    override func configureBarButtons() {
        
        switch detailItemShowStyle {
        case .AuthorInsert:
            self.editing = true
            navigationItem.leftBarButtonItems = [cancelBarButtonItem]
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            toolbarItems = []
            navigationController?.toolbarHidden = true

        case .AuthorRead:
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [addNewReviewBarButtonItem]
        case .AuthorModify:
            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = [editButtonItem()]
            toolbarItems = [flexibleSpaceBarButtonItem, deleteBarButtonItem]
        case .PublicRead:
            navigationItem.leftBarButtonItems = [closeBarButtonItem]
            navigationItem.rightBarButtonItems = []
            toolbarItems = [addNewReviewBarButtonItem, flexibleSpaceBarButtonItem,likeBarButtonItem]
        }
        
        // If self is in a navigation stack then change leftBarButton to navigation default back button.
        // So call super's configureBarButtons.
        super.configureBarButtons()
    }

    override func updateUI() {
        super.updateUI()
        let usersLikeMeSet = detailItem!.mutableSetValueForKey(SectionUnique.UsersLikeMe.rawValue)
        likeBarButtonItem.on = usersLikeMeSet.containsObject(User.currentUser())
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

    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedInfoController.sections[section]
        let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier)!
        return sectionUnique.name
    }
    
    // MARK: - Fetched Info Controller Data Source
    
    override func identifiersForSectionInfos() -> [String] {
        if editing == false {
            // Public read
            return SectionUnique.allValues
        } else {
            // Private write
           return [SectionUnique.OverView.rawValue]
        }
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
    

    
    override func cellKeysBySectionIdentifier(identifier: String) -> [String]? {
        
        let sectionUnique = SectionUnique(rawValue: identifier)!
        
        guard case .OverView = sectionUnique  else { return nil }
        
        return [
            Experiment.Constants.TitleKey,
            Experiment.Constants.BodyKey,
            CloudManager.Constants.CreationDateKey
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
    static let UserCellReuseIdentifier = "UserCell"
    static let ReviewCellReuseIdentifier = "ReviewCell"
}


extension ExperimentDetailViewController {
    // MARK: - Unwind Segue
    @IBAction func cancelToExperimentDetail(segue: UIStoryboardSegue) {
        guard let dvc = segue.sourceViewController as? DetailViewController else { return }
        NSManagedObjectContext.defaultContext().deleteObject(dvc.detailItem!)
    }
    
    @IBAction func saveToExperimentDetail(segue: UIStoryboardSegue) {
        if let rvc = segue.sourceViewController as? ReviewViewController {
            let review = rvc.review!
            review.body = rvc.bodyTextView.text
            let sectionUnique = SectionUnique.Reviews
            addObject(review, forToManyRelationshipKey: sectionUnique.rawValue)
            NSManagedObjectContext.saveDefaultContext()
        }
    }
    
    @IBAction func closeToExperimentDetail(segue: UIStoryboardSegue) {
    }
    
}

