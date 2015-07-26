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
            updateUI()
        }
    }
    
    var tableViewDataStruct = TableViewDataStruct()
    
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
            toggleEditingMode(editing)
        }
    }
    
    private func toggleEditingMode(editing: Bool) {
        tableView.beginUpdates()
        
        for (sectionIndex, section) in tableViewDataStruct.sections.enumerate() {
            switch section.identifier {
            case .Attribute:
                tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Reviews:
                var indexPath: NSIndexPath!
                let objectsCount = experiment.mutableSetValueForKey(section.identifier.key).count
                if editing {
                    indexPath = NSIndexPath(forRow: objectsCount, inSection: sectionIndex)
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } else {
                    indexPath = NSIndexPath(forRow: objectsCount , inSection: sectionIndex)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
                
            default: break
            }
            
        }
        
        
        tableView.endUpdates()
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
            case Insert(String)
            case RightDetail(String, String)
            case TextField(String, String?)
            
            var cellReuseIdentifier: String {
                switch self {
                case .Basic(_):
                    return "BasicCell"
                case .Insert(_):
                    return "BasicCell"
                case .RightDetail(_, _):
                    return "RightDetailCell"
                case .TextField(_, _):
                    return "TextFieldCell"
                }
            }
        }
        
    }
    
    

    
    struct TableViewDataStruct {
        
        var sections = [SectionStyle]()
        
        init() {
            var sections = [SectionStyle]()
            for identifier in SectionStyle.Identifier.allIdentifiers {
                let sectionStyle = SectionStyle.styleForIdentifier(identifier)
                sections.append(sectionStyle)
            }
            
            self.sections = sections
        }
        
        // MARK: - Table View Data Struct
        
        func cellStyleAtIndexPath(indexPath: NSIndexPath) -> Storyboard.CellStyle? {
            
            guard indexPath.section < sections.count else { return nil }
            let sectionStyle = sections[indexPath.section]
            
            switch sectionStyle {
            case .Attribute(_, let styles):
                guard indexPath.row < styles.count else { return nil }
                return styles[indexPath.row]
                
            case .ToOneRelationship(_, let style):
                return style
                
            case .ToManyRelationship(_, let style):
                return style
                
            }
        }
        
    
        enum SectionStyle {
            case Attribute(Identifier, [Storyboard.CellStyle])
            case ToOneRelationship(Identifier, Storyboard.CellStyle)
            case ToManyRelationship(Identifier, Storyboard.CellStyle)
            
            static func styleForIdentifier(identifier: Identifier) -> SectionStyle {
                switch identifier {
                case .Attribute:
                    let titleCellStyle = Storyboard.CellStyle.TextField(Experiment.Constants.TitleKey, Experiment.Constants.TitleKey)
                    let bodyCellStyle =  Storyboard.CellStyle.TextField(Experiment.Constants.BodyKey, Experiment.Constants.BodyKey)
                    return .Attribute(identifier, [titleCellStyle, bodyCellStyle])
                    
                case .WhoPost:
                    let whoPostCellStyle = Storyboard.CellStyle.Basic(User.Constants.NameKey)
                    return .ToOneRelationship(identifier, whoPostCellStyle)
                    
                case .Reviews:
                    let reviewCellStyle = Storyboard.CellStyle.RightDetail("\(Review.Constants.WhoReviewKey).\(User.Constants.NameKey)", Root.Constants.CreateDateKey)
                    return .ToManyRelationship(identifier, reviewCellStyle)
                    
                case .UsersLikeMe:
                    let reviewCellStyle = Storyboard.CellStyle.Basic(User.Constants.NameKey)
                    return .ToManyRelationship(identifier, reviewCellStyle)

                }
            }
            
            var identifier: Identifier {
                switch self {
                case .Attribute(let id, _):
                    return id
                case .ToOneRelationship(let id, _):
                    return id
                case .ToManyRelationship(let id, _):
                    return id
                }
            }
            
            var name: String {
                return identifier.key
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
        
        
        


    }
    
    
   
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewDataStruct.sections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < tableViewDataStruct.sections.count else { return 0 }
        let sectionStyle = tableViewDataStruct.sections[section]
        return numberOfRowsForSectionStyle(sectionStyle)
        
    }
    
    private func numberOfRowsForSectionStyle(sectionStyle : TableViewDataStruct.SectionStyle) -> Int {
        switch sectionStyle {
        case .Attribute(_, let styles):
            return styles.count
            
        case .ToOneRelationship(let identifier, _):
            return experiment.valueForKey(identifier.key) != nil ? 1 : 0
            
        case .ToManyRelationship(let identifier, _):
            let managedObjectSet = experiment.mutableSetValueForKey(identifier.key)
            return (identifier == .Reviews && editing) ? managedObjectSet.count + 1 : managedObjectSet.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cellStyle = tableViewDataStruct.cellStyleAtIndexPath(indexPath) else { return UITableViewCell() }
        guard let objectToConfigureCell = objectToConfigureCellAtIndexPath(indexPath) else {
            // Only happen, when the section last row show insertStyle at bottom while editing mode.
            let identifier = tableViewDataStruct.sections[indexPath.section].identifier
            return cellToInsertForSectionIdentifier(identifier)
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(cellStyle.cellReuseIdentifier, forIndexPath: indexPath)
        configureCell(cell, useCellStyle: cellStyle, withManagedObject: objectToConfigureCell)
        return cell
    }
    
    private func cellToInsertForSectionIdentifier(identifier: TableViewDataStruct.SectionStyle.Identifier) -> UITableViewCell {
        if identifier == .Reviews {
            let cellStyle = Storyboard.CellStyle.Insert(Review.Constants.EntityNameKey)
            guard let cell = tableView.dequeueReusableCellWithIdentifier(cellStyle.cellReuseIdentifier) else { return UITableViewCell() }
            configureCell(cell, useCellStyle: cellStyle, withManagedObject: nil)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    private func objectToConfigureCellAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject? {
        let sectionStyle = tableViewDataStruct.sections[indexPath.section]
        switch sectionStyle {
        case .Attribute(_, _):
            return experiment
            
        case .ToOneRelationship(let identifier, _):
            return experiment.valueForKey(identifier.key) as? NSManagedObject
            
            
        case .ToManyRelationship(let identifier, _):
            let managedObjects = experiment.mutableSetValueForKey(identifier.key).allObjects as! [NSManagedObject]
            guard indexPath.row < managedObjects.count else { return nil }
            return managedObjects[indexPath.row]
            
        }

    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionStyle = tableViewDataStruct.sections[section]
        return sectionStyle.name
    }
    
    
    
    private func configureCell(cell: UITableViewCell, useCellStyle cellStyle: Storyboard.CellStyle, withManagedObject managedObject: NSManagedObject?) {
        
        switch cellStyle {
        case .Basic(let key):
            guard managedObject != nil else { return }
            cell.textLabel?.text = managedObject!.descriptionForKeyPath(key)
            
        case .Insert(let entityName):
            cell.textLabel?.text = "Add New \(entityName)."
            
        case .RightDetail(let keyToConfigTextLabel, let keyToConfigDetailTextLabel):
            guard managedObject != nil else { return }
            cell.textLabel?.text = managedObject!.descriptionForKeyPath(keyToConfigTextLabel)
            cell.detailTextLabel?.text = managedObject!.descriptionForKeyPath(keyToConfigDetailTextLabel)
            
        case .TextField(let title, let keyToBeEdite):
            if let textFieldTableViewCell = cell as? TextFieldTableViewCell {
                textFieldTableViewCell.titleLabel.text = title
                if keyToBeEdite != nil {
                    guard managedObject != nil else { return }
                    textFieldTableViewCell.textField.text = managedObject!.descriptionForKeyPath(keyToBeEdite!)
                }
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
        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
        switch sectionIdentifier {
        case .Reviews:
            return true
        default: break
        }
        
        return false
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
        
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
        
        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
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

extension NSManagedObject {
    func descriptionForKeyPath(keyPath: String) -> String {
        return (valueForKeyPath(keyPath) as? CustomStringConvertible)?.description ?? ""
    }
}




