//
//  ExperimentDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import CloudKit



class ExperimentDetailViewController: UIViewController {
    
    private enum SegueID: String {
        case ShowUserDetail
        case AddNewReview
    }
    
    private struct Constants {
        static let AttributeSectionKey = "Attribute"
    }
    
    struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
        static let EmptyStyleCellReuseIdentifier = "EmptyStyleCell"
        static let LoadingStyleCellReuseIdentifier = "LoadingStyleCell"
        static let InsertStyleCellReuseIdentifier = "InsertStyleCell"
        static let NumberCellReuseIdentifier = "NumberCell"
        static let BoolCellReuseIdentifier = "BoolCell"
        static let TextCellReuseIdentifier = "TextCell"
        static let DateCellReuseIdentifier = "DateCell"
        static let ImageCellReuseIdentifier = "ImageCell"
        static let DetailItemCellReuseIdentifier = "DetailItemCell"
        static let UserCellReuseIdentifier = "UserCell"
        static let ReviewCellReuseIdentifier = "ReviewCell"
    }
    
    
    // MARK: - Properties

    var experiment: CKRecord?
    
    func author(completionHandler: (CKRecord) -> ()) {
        // Fetch from cache first.
        guard let authorID = experiment?.valueForKey(RecordKey.CreatorUserRecordID) as? CKRecordID else { return dispatch_async(dispatch_get_main_queue()) { completionHandler(self.currentUser!) } }
        var author = userCache.objectForKey(authorID.recordName) as? CKRecord
        guard author == nil else { completionHandler(author!) ; return print("fetched author from cache.") }

        // Fetch from cloud second.
        
        let fetchedAuthorBlock: (CKRecord?, NSError?) -> Void = {
            [weak self] (record, error) in
            guard error == nil else { print(error?.localizedDescription) ; return }
            guard let weakSelf = self else { return }
            author = record!
            weakSelf.userCache.setObject(author!, forKey: authorID.recordName)
            print("fetched author from cloud.")
            dispatch_async(dispatch_get_main_queue()) { completionHandler(author!) }
        }
        
        guard authorID.recordName != CKOwnerDefaultName else {
            let fetchCurrentUserRecordOperation = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
            fetchCurrentUserRecordOperation.perRecordCompletionBlock = { fetchedAuthorBlock($0, $2) }
            publicCloudDatabase.addOperation(fetchCurrentUserRecordOperation)
            return print("fetched author who is current user from cloud.")
        }
        
        publicCloudDatabase.fetchRecordWithID(authorID, completionHandler: fetchedAuthorBlock)
        
    }
    
    
    var userCache: NSMutableDictionary {
        return AppDelegate.Cache.Manager.userCache
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet var postBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var addNewReviewBarButtonItem: UIBarButtonItem!
    @IBOutlet var likeBarButtonItem: SwitchBarButtonItem! {
        didSet {
            likeBarButtonItem.offStateTitle = "Like"
            likeBarButtonItem.onStateTitle = "Liking"
        }
    }
    @IBOutlet var deleteBarButtonItem: UIBarButtonItem!
    
    @IBOutlet var flexibleSpaceBarButtonItem: UIBarButtonItem!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideBarSeparator()
        configureBarButtons()
    }
    
    // MARK: - View Configure
    
    func configureBarButtons() {
        self.editing = true
        navigationItem.leftBarButtonItems = [cancelBarButtonItem]
        navigationItem.rightBarButtonItems = [postBarButtonItem]
        toolbarItems = []
        navigationController?.toolbarHidden = true

    }
}

extension ExperimentDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return  sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionContent = sections[section].content
        switch sectionContent {
        case .Attribute(keys: let keys):
            return keys.count
            
        case .ToOneRelationship(key: _):
            return 1
            
        case .ToManyRelationship(key: let key):
            guard let references = experiment?.valueForKey(key) as? [CKReference] else { return 0 }
            return references.count != 0 ? references.count : 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellReuseIdentifier = cellReuseIdentifierAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let sectionContent = sections[indexPath.section].content
        switch sectionContent {
        case .Attribute(keys: let keys):
            configureCell(cell, forKey: keys[indexPath.row])
            
        case .ToOneRelationship(key: let key):
            configureCell(cell, forToOneRelationshiprKey: key)
            
        case .ToManyRelationship(key: _):
            return
        }
        
        
//        guard let experimentCell = cell as? ExperimentTableViewCell else { abort() }
//        let experiment = self.experiments[indexPath.row]
    }
    
    private func configureCell(cell: UITableViewCell, forKey key: String) {
        switch key {
        case ExperimentKey.Title, ExperimentKey.Body:
            guard let textFieldTableViewCell = cell as? TextFieldTableViewCell else { abort()  }
            textFieldTableViewCell.titleLabel.text = key.capitalizedString
            textFieldTableViewCell.textField.text = experiment?.valueForKey(key) as? String
            
        case RecordKey.CreationDate:
            guard let dateTableViewCell = cell as? DateTableViewCell else { abort()  }
            dateTableViewCell.textLabel?.text = key.capitalizedString
            let date = experiment?.valueForKey(key) as? NSDate ?? NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
            dateFormatter.timeStyle = .ShortStyle
            dateTableViewCell.detailTextLabel?.text = dateFormatter.stringFromDate(date)
            
        default:
            abort()
        }
    }
    
    private func configureCell(cell: UITableViewCell, forToOneRelationshiprKey key: String) {
        switch key {
        case ExperimentKey.WhoPost:
            guard let authorCell = cell as? AuthorTableViewCell  else { abort()  }
            author { (author) in
                authorCell.nameLabel.text = author.valueForKey(UserKey.DisplayName) as? String
                guard let imageData = (author.valueForKey(UserKey.ProfileImageAsset) as? CKAsset)?.data else { return }
                authorCell.profileImage = UIImage(data: imageData)
            }
            
        default:
            abort()
        }
    }
    
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionUnique = SectionUnique(rawValue: sections[section].identifier) else { return nil }
        return sectionUnique.name
    }
    
    // MARK: - Table View Data Structure
    
    
    var sections: [SectionInfo] {
        // Sections 1: OverView
        var result = [SectionInfo]()
        let keys =  [
            ExperimentKey.Title,
            ExperimentKey.Body,
            RecordKey.CreationDate
        ]
        result.append(SectionInfo(identifier: SectionUnique.OverView.rawValue, content: .Attribute(keys: keys)))
        
        // Sections 2: Author
        var identifier = SectionUnique.WhoPost.rawValue
        result.append(SectionInfo(identifier:identifier, content: .ToOneRelationship(key: identifier)))
        
//        // Sections 3: Reviews
//        identifier = SectionUnique.Reviews.rawValue
//        result.append(SectionInfo(identifier:identifier, content: .ToManyRelationship(key: identifier)))
//        
//        // Sections 3: UsersLikeMe
//        identifier = SectionUnique.UsersLikeMe.rawValue
//        result.append(SectionInfo(identifier:identifier, content: .ToManyRelationship(key: identifier)))
        
        return result
    }
    
    
    private func cellReuseIdentifierAtIndexPath(indexPath: NSIndexPath) -> String {
        let sectionInfo = sections[indexPath.section]
        guard let sectionUnique = SectionUnique(rawValue: sectionInfo.identifier) else { abort() }
        switch sectionUnique {
        case .OverView:
            guard case SectionInfo.SectionContent.Attribute(keys: let keys) = sectionInfo.content else { abort() }
            return cellReuseIdentifierForKey(keys[indexPath.row])
        case .WhoPost:
            return Storyboard.UserCellReuseIdentifier
        case .Reviews:
            return Storyboard.ReviewCellReuseIdentifier
        case .UsersLikeMe:
            return Storyboard.UserCellReuseIdentifier
        }
    }
    
    private func cellReuseIdentifierForKey(key: String) -> String {
        switch key {
        case ExperimentKey.Title, ExperimentKey.Body:
            return Storyboard.TextCellReuseIdentifier
            
        case RecordKey.CreationDate:
            return Storyboard.DateCellReuseIdentifier
            
        default:
            abort()
        }
    }
    
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
    
    struct SectionInfo {
        var identifier: String
        var content: SectionContent

        enum SectionContent {
            case Attribute(keys:[String])
            case ToOneRelationship(key:String)
            case ToManyRelationship(key:String)
        }
        
    }

}
