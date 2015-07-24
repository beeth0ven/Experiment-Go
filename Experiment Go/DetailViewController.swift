//
//  DetailViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var experiment: Experiment! {
        didSet {
            // Update the view.
            configureDataStruct()
            updateUI()
        }
    }
    
    var sections = [SectionInfo]()
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.estimatedRowHeight = Storyboard.TableViewEstimatedRowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureDataStruct()
        self.configureBarButtons()
        updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        oberveTextField()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopOberveTextField()
    }
    
    // MARK: - User Actions
    
    override func setEditing(editing: Bool, animated: Bool) {
        if self.editing != editing {
            super.setEditing(editing, animated: true)
            tableView.setEditing(editing, animated: true)
        }
    }
    
    
    
    @IBAction func save(sender: UIBarButtonItem) {
        dismissSelfAndSveContext(nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissSelfAndSveContext {
            [unowned self] in
            if self.experiment.inserted {
                NSManagedObjectContext.defaultContext().deleteObject(self.experiment!)
            }
        }
    }
    
    private func dismissSelfAndSveContext(completion: (() -> Void)?) {
        presentingViewController?.dismissViewControllerAnimated(true) {
            completion?()
            NSManagedObjectContext.saveDefaultContext()
        }
    }
    
    private func doLikeExperiment() {
        
    }
    
    private func doUnLikeExperiment() {
        
    }
    
    private func doDeleteExperiment() {
        dismissSelfAndSveContext {
            [unowned self] in
            NSManagedObjectContext.defaultContext().deleteObject(self.experiment!)
        }
    }
    
    
    // MARK: - View Configure
    
    private func configureBarButtons() {
        if !experiment.inserted {
            navigationItem.rightBarButtonItem = editButtonItem()
        } else {
            editing = true
        }
    }
    
    private func updateUI() {
        configureView()
        tableView?.reloadData()
    }
    
    private func configureView() {
        // Update the user interface for the detail item.
        
    }
    
}




extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
        
        enum CellStyle {
            case Basic(String)
            case RightDetail(String, String)
            case TextField(String, String?)
            
            var cellReuseIdentifier: String {
                switch self {
                case .Basic(_):
                    return "BasicCell"
                case .RightDetail(_, _):
                    return "RightDetailCell"
                case .TextField(_, _):
                    return "TextFieldCell"
                }
            }
        }
        
    }
    
    // MARK: - Configure Data Struct
    
    private func configureDataStruct() {
        
        var result = [SectionInfo]()
        for identifier in SectionInfo.Identifier.allIdentifiers {
            let sectionInfo = sectionInfoForIdentifier(identifier)
            result.append(sectionInfo)
        }
        
        sections = result
        
    }
    

    
    // MARK: - Table View Data Struct
    
    struct SectionInfo {
        var identifier: Identifier
        var cellStyles: [Storyboard.CellStyle]
        var name: String {
              return identifier.key
        }
        
        init(identifier: Identifier, cellStyles: [Storyboard.CellStyle]) {
            self.identifier = identifier
            self.cellStyles = cellStyles
        }
        
        var indexTitle: String {
            return String(name.characters.first).uppercaseString
        }
        
        var numberOfObjects: Int {
            return cellStyles.count
        }
        
        enum Identifier {
            case Attribute
            case WhoPost
            case Reviews
            case UsersLikeMe
            
            var key: String {
                get {
                    switch self {
                    case .Attribute:
                        return Experiment.Constants.AttributeKey
                    case .WhoPost:
                        return Experiment.Constants.WhoPostKey
                    case .Reviews:
                        return Experiment.Constants.ReviewsKey
                    case .UsersLikeMe:
                        return Experiment.Constants.UsersLikeMeKey
                    }
                }
            }

            
            static var allIdentifiers: [Identifier] {
                return [
                    .Attribute,
                    .WhoPost,
                    .Reviews,
                    .UsersLikeMe,
                ]
            }
        }
        
    }
    
    
    func sectionInfoForIdentifier(identifier: SectionInfo.Identifier) -> SectionInfo {
        switch identifier {
        case .Attribute:
            let titleCellStyle = Storyboard.CellStyle.TextField(Experiment.Constants.TitleKey, experiment.title)
            let bodyCellStyle =  Storyboard.CellStyle.TextField(Experiment.Constants.BodyKey, experiment.body)
            return SectionInfo(identifier: identifier, cellStyles: [titleCellStyle, bodyCellStyle])
            
        case .WhoPost:
            let whoPostCellStyle = cellStyleFromManagedObject(experiment.whoPost!)!
            return SectionInfo(identifier: identifier, cellStyles: [whoPostCellStyle])
            
        case .Reviews:
            return sectionInfoFromRelationshipIdentifier(.Reviews)
            
        case .UsersLikeMe:
            return sectionInfoFromRelationshipIdentifier(.UsersLikeMe)
            
        }
    }
    
    
    private func sectionInfoFromRelationshipIdentifier(identifier: SectionInfo.Identifier) -> SectionInfo {
        
        var cellStyles: [Storyboard.CellStyle] = []
        
        if let relationshipObjectSet = experiment.valueForKey(identifier.key) as? NSSet {
            if let managedObjects = relationshipObjectSet.allObjects as? [NSManagedObject] {
                cellStyles = managedObjects.map { self.cellStyleFromManagedObject($0)! }
            }
        }
        
        return SectionInfo(identifier: identifier, cellStyles: cellStyles)
    }
    
    
    private func cellStyleFromManagedObject(managedObject: NSManagedObject) -> Storyboard.CellStyle? {
        var result: Storyboard.CellStyle? = nil
        if let review = managedObject as? Review {
            result = Storyboard.CellStyle.RightDetail(review.whoReview!.name!, review.createDate!.description)
        } else if let user = managedObject as? User {
            result = Storyboard.CellStyle.Basic(user.name!)
        }
        return result
    }
    
    
    func cellStyleAtIndexPath(indexPath: NSIndexPath) -> Storyboard.CellStyle? {
        return sections[indexPath.section].cellStyles[indexPath.row]
    }

    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let experimentSection = sections[section]
        return  experimentSection.cellStyles.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if let cellStyle = cellStyleAtIndexPath(indexPath) {
            cell = tableView.dequeueReusableCellWithIdentifier(cellStyle.cellReuseIdentifier, forIndexPath: indexPath)
            self.configureCell(cell!, useCellStyle: cellStyle)
        }
        
        return cell ?? UITableViewCell()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let experimentSectionInfo = sections[section]
        return experimentSectionInfo.name
    }
    
    
    
    func configureCell(cell: UITableViewCell, useCellStyle cellStyle: Storyboard.CellStyle) {
        
        switch cellStyle {
        case .Basic(let title):
            cell.textLabel?.text = title
        case .RightDetail(let title, let detailText):
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detailText
        case .TextField(let title, let editableText):
            if let textFieldTableViewCell = cell as? TextFieldTableViewCell {
                textFieldTableViewCell.titleLabel.text = title
                textFieldTableViewCell.textField.text = editableText
                textFieldTableViewCell.textField.enabled = editing
                textFieldTableViewCell.textField.delegate = self
            }
        }
        
    }
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.editingStyle == .Insert {
            self.tableView(tableView, commitEditingStyle: cell.editingStyle, forRowAtIndexPath: indexPath)
        }
        
    }

    // MARK: - Table View Edited Method
    
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let sectionIdentifier = sections[indexPath.section].identifier
        switch sectionIdentifier {
        case .Reviews:
            return true
        default: break
        }
        
        return false
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        let sectionIdentifier = sections[indexPath.section].identifier
        
        switch sectionIdentifier {
        case .Reviews:
            let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
            if (indexPath.row == numberOfRows - 1) && tableView.editing {
                return .Insert
            } else {
                return .Delete
            }
        default: break
        }
        
        
        return .None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let sectionIdentifier = sections[indexPath.section].identifier
        switch sectionIdentifier {
        case .Reviews:
            commitEditingStyle(editingStyle, forReviewAtIndexPath: indexPath)
        default: break
        }
        
    }
    
    private func commitEditingStyle(editingStyle: UITableViewCellEditingStyle, forReviewAtIndexPath indexPath: NSIndexPath) {
//        switch editingStyle {
//        case .Insert:
//            let review = Review.insertNewReview()
//            fetchedDataController.addRelationshipObject(review, withSectionIdentifier: .Reviews)
//
//        case .Delete:
//            fetchedDataController.removeRelationshipObjectAtIndexPath(indexPath)
//
//        default: break
//        }
    }
    
}



extension DetailViewController: UITextFieldDelegate {
    // MARK: - Text Field Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func handleTextFieldTextDidChange(notification: NSNotification) {
        guard let textField = notification.object as? UITextField else { return }
        if let textFieldTableViewCell = textFieldTableViewCellWhichContainsTextField(textField) {
            experiment?.setValue(textField.text, forKey: textFieldTableViewCell.titleLabel.text!)
        }
    }
    
    private func oberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self,
            selector: "handleTextFieldTextDidChange:",
            name: UITextFieldTextDidChangeNotification,
            object: nil
        )
    }
    
    private func stopOberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }
    
    func textFieldTableViewCellWhichContainsTextField(textField: UITextField) -> TextFieldTableViewCell? {
        var superView: UIView? = textField
        repeat { superView = superView!.superview }
            while  (superView != nil) && (superView is TextFieldTableViewCell) == false
        return superView == nil ? nil : (superView as! TextFieldTableViewCell)
    }
    
}






