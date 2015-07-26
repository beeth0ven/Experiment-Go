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
    
    private struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
    }

    
    // MARK: - Properties
    
    var detailItem: NSManagedObject! {
        didSet {
            // Update the view.
            updateUI()
        }
        
    }

    lazy var fetchedInfoController: FetchedInfoController = {
        let lazyCreateFetchedInfoController = FetchedInfoController()
        lazyCreateFetchedInfoController.dataSource = self
        return lazyCreateFetchedInfoController
    }()
    
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
    
    // MARK: - User Actions
    
    override func setEditing(editing: Bool, animated: Bool) {
        if self.editing != editing {
            super.setEditing(editing, animated: true)
            tableView.setEditing(editing, animated: true)
            toggleEditingMode(editing)
        }
    }
    
    private func toggleEditingMode(editing: Bool) {
        //        tableView.beginUpdates()
        //
        //        for (sectionIndex, section) in tableViewDataStruct.sections.enumerate() {
        //            switch section.identifier {
        //            case .Attribute:
        //                tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        //            case .Reviews:
        //                var indexPath: NSIndexPath!
        //                let objectsCount = experiment.mutableSetValueForKey(section.identifier.key).count
        //                if editing {
        //                    indexPath = NSIndexPath(forRow: objectsCount, inSection: sectionIndex)
        //                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        //                } else {
        //                    indexPath = NSIndexPath(forRow: objectsCount , inSection: sectionIndex)
        //                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        //                }
        //
        //            default: break
        //            }
        //
        //        }
        //
        //
        //        tableView.endUpdates()
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        dismissSelfAndSveContext(nil)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissSelfAndSveContext {
            [unowned self] in
            if self.detailItem.inserted {
                NSManagedObjectContext.defaultContext().deleteObject(self.detailItem!)
            }
        }
    }
    
    private func dismissSelfAndSveContext(completion: (() -> Void)?) {
        presentingViewController?.dismissViewControllerAnimated(true) {
            completion?()
            NSManagedObjectContext.saveDefaultContext()
        }
    }
    
    
    // MARK: - View Configure
    
    private func configureBarButtons() {
        if !detailItem.inserted {
            navigationItem.rightBarButtonItem = editButtonItem()
        } else {
            editing = true
        }
    }
    
    private func updateUI() {
        tableView?.reloadData()
    }
}




extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedInfoController.sections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < fetchedInfoController.sections.count else { return 0 }
        let sectionInfo = fetchedInfoController.sections[section]
        return numberOfRowsForSectionStyle(sectionInfo)
        
    }
    
    private func numberOfRowsForSectionStyle(sectionInfo : SectionInfo) -> Int {
        switch sectionInfo.style {
        case .Attribute:
            return sectionInfo.cellInfos.count
            
        case .ToOneRelationship(let toOneRelationshipKey):
            return detailItem.valueForKey(toOneRelationshipKey) != nil ? 1 : 0
            
        case .ToManyRelationship(let toManyRelationshipKey):
            let managedObjectSet = detailItem.mutableSetValueForKey(toManyRelationshipKey)
            return managedObjectSet.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cellInfo = fetchedInfoController.cellInfoAtIndexPath(indexPath) else { return UITableViewCell() }
        guard let objectToConfigureCell = objectToConfigureCellAtIndexPath(indexPath) else {
            // Only happen, when the section last row show insertStyle at bottom while editing mode.
            //            let identifier = tableViewDataStruct.sections[indexPath.section].identifier
            //            return cellToInsertForSectionIdentifier(identifier)
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.style.cellReuseIdentifier, forIndexPath: indexPath)
        let configureCellOperation = cellInfo.style.configureCellOperation
        configureCellOperation(cell, objectToConfigureCell)
        return cell
    }
    
    //    private func cellToInsertForSectionIdentifier(identifier: TableViewDataStruct.SectionStyle.Identifier) -> UITableViewCell {
    //        if identifier == .Reviews {
    //            let cellStyle = Storyboard.CellStyle.Insert(Review.Constants.EntityNameKey)
    //            guard let cell = tableView.dequeueReusableCellWithIdentifier(cellStyle.cellReuseIdentifier) else { return UITableViewCell() }
    //            configureCell(cell, useCellStyle: cellStyle, withManagedObject: nil)
    //            return cell
    //        } else {
    //            return UITableViewCell()
    //        }
    //    }
    
    private func objectToConfigureCellAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject? {
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        switch sectionInfo.style {
        case .Attribute:
            return detailItem
            
        case .ToOneRelationship(let toOneRelationshipKey):
            return detailItem.valueForKey(toOneRelationshipKey) as? NSManagedObject
            
            
        case .ToManyRelationship(let toManyRelationshipKey):
            let managedObjects = detailItem.mutableSetValueForKey(toManyRelationshipKey).allObjects as! [NSManagedObject]
            guard indexPath.row < managedObjects.count else { return nil }
            return managedObjects[indexPath.row]
            
        }
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedInfoController.sections[section]
        return sectionInfo.key
    }
    
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        //        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        //        if cell.editingStyle == .Insert {
        //            self.tableView(tableView, commitEditingStyle: cell.editingStyle, forRowAtIndexPath: indexPath)
        //        }
        
    }
    
    // MARK: - Table View Edited Method
    
    
    
    //    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    //        // Return false if you do not want the specified item to be editable.
    //        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
    //        switch sectionIdentifier {
    //        case .Reviews:
    //            return true
    //        default: break
    //        }
    //
    //        return false
    //    }
    
    //
    //    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
    //
    //        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
    //
    //        switch sectionIdentifier {
    //        case .Reviews:
    //            let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
    //            if (indexPath.row == numberOfRows - 1) && tableView.editing {
    //                return .Insert
    //            } else {
    //                return .Delete
    //            }
    //        default: break
    //        }
    //
    //
    //        return .None
    //    }
    //
    //    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    //
    //        let sectionIdentifier = tableViewDataStruct.sections[indexPath.section].identifier
    //        switch sectionIdentifier {
    //        case .Reviews:
    //            commitEditingStyle(editingStyle, forReviewAtIndexPath: indexPath)
    //        default: break
    //        }
    //
    //    }
    
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
            detailItem?.setValue(textField.text, forKey: textFieldTableViewCell.titleLabel.text!)
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
    
    func destinationEntityNameForRelationshipKey(key: String) -> String? {
        let relationshipDescription = self.entity.relationshipsByName[key]
        return relationshipDescription?.destinationEntity?.name
    }
}


extension DetailViewController: FetchedInfoControllerDataSource {
    
    private struct Constants {
        static let AttributeSectionKey = "Attribute"
    }
    
    
    
    func keysForSectionInfos() -> [String] {
        var relationshipNames = detailItem.entity.relationshipsByName.keys.array
        relationshipNames.insert(Constants.AttributeSectionKey, atIndex: 0)
        return relationshipNames
    }
    
    func sectionInfoForKey(key: String) -> SectionInfo {
        let style: SectionInfo.Style!
        if key == Constants.AttributeSectionKey {
            style = .Attribute
        } else {
            let relationshipDescription = detailItem.entity.relationshipsByName[key]!
            style = relationshipDescription.toMany ? .ToManyRelationship(key) : .ToOneRelationship(key)
        }
        return SectionInfo(key: key, style: style)
    }
    
    
    
    func keysForCellInfosBySectionInfo(sectionInfo: SectionInfo) -> [String] {
        switch sectionInfo.style {
        case .Attribute:
            return detailItem.entity.attributesByName.keys.array
        case .ToOneRelationship(let toOneRelationshipName):
            return [detailItem.destinationEntityNameForRelationshipKey(toOneRelationshipName)!]
        case .ToManyRelationship(let toManyRelationshipName):
            return [detailItem.destinationEntityNameForRelationshipKey(toManyRelationshipName)!]
        }
    }
    
    func cellInfoForKey(key: String, bySectionInfo sectionInfo: SectionInfo) -> CellInfo {
        let style: CellInfo.Style!
        switch sectionInfo.style {
        case .Attribute:
            style = .RightDetail({
                (cell, managedObject) in
                cell.textLabel?.text = key
                cell.detailTextLabel?.text = managedObject.descriptionForKeyPath(key)
            })
            
        case .ToOneRelationship(_):
            style = .RightDetail({
                (cell, managedObject) in
                cell.textLabel?.text = managedObject.entity.name
                cell.detailTextLabel?.text = managedObject.descriptionForKeyPath(Root.Constants.CreateDateKey)
            })
            
        case .ToManyRelationship(_):
            style = .RightDetail({
                (cell, managedObject) in
                cell.textLabel?.text = managedObject.entity.name
                cell.detailTextLabel?.text = managedObject.descriptionForKeyPath(Root.Constants.CreateDateKey)
            })
            
        }
        return CellInfo(key: key, style: style)
    }
}

