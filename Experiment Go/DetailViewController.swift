//
//  DetailViewController.swift
//  Test
//
//  Created by luojie on 7/14/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, FetchedInfoControllerDataSource, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    var detailItem: RootObject! {
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
    

    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
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
            // Toggle Editing Mode Only when the detailItem is not new one.
            if detailItem.inserted == false { toggleEditingMode(editing) }
        }
    }
    
    private func toggleEditingMode(editing: Bool) {
        let options: UIViewAnimationOptions = editing ? .TransitionCurlUp : .TransitionCurlDown
        UIView.transitionWithView(navigationController!.view,
            duration: 0.4,
            options: options,
            animations: {
                self.fetchedInfoController.reloadDataStruct()
                self.configureBarButtons()
                self.tableView.reloadData()
            },
            completion: nil)
    }
    
    // MARK: - View Configure
    
    func configureBarButtons() {
        
        if navigationController?.viewControllers.first != self {
            navigationItem.leftBarButtonItem = nil
        }
        
    }
    
    func updateUI() {
        tableView?.reloadData()
    }
    
    
    // MARK: - Help Method
    
    func addObject(rootObject: RootObject, forToManyRelationshipKey key: String) -> Bool {
        let sectionInfo = sectionInfoForIdentifier(key)
        guard case .ToManyRelationship(let key,let isOrderdBefore) = sectionInfo.style else { return false }
        let relationshipSet = detailItem!.mutableSetValueForKey(key)
        
        guard relationshipSet.containsObject(rootObject) == false else { return false }
        guard detailItem.destinationEntityNameForRelationshipKey(key) == rootObject.entity.name else { return false }
        relationshipSet.addObject(rootObject)
        
        let relationshipAsArray = (relationshipSet.allObjects as! [RootObject]).sort(isOrderdBefore)
        guard
            let row: Int = relationshipAsArray.indexOf(rootObject),
            let section: Int = identifiersForSectionInfos().indexOf(key)
            else { return false }
        
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        tableView.beginUpdates()
        if detailItem.mutableSetValueForKey(key).count == 1 {
            // Empty Cell Change to Normal Cell
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        tableView.endUpdates()
        return true
    }
    
    func removeObject(rootObject: RootObject, forToManyRelationshipKey key: String) -> Bool {
        
        let sectionInfo = sectionInfoForIdentifier(key)
        guard case .ToManyRelationship(let key,let isOrderdBefore) = sectionInfo.style else { return false }
        let relationshipSet = detailItem!.mutableSetValueForKey(key)
        
        guard relationshipSet.containsObject(rootObject) == true else { return false }
        
        let relationshipAsArray = (relationshipSet.allObjects as! [RootObject]).sort(isOrderdBefore)
        guard
            let row: Int = relationshipAsArray.indexOf(rootObject),
            let section: Int = identifiersForSectionInfos().indexOf(key)
            else { return false }
        let indexPath = NSIndexPath(forRow: row, inSection: section)

        relationshipSet.removeObject(rootObject)
        
        tableView.beginUpdates()
        if detailItem.mutableSetValueForKey(key).count == 0 {
            // Normal Cell Change to Empty Cell
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        tableView.endUpdates()
        
        return true
        
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedInfoController.sections.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < fetchedInfoController.sections.count else { return 0 }
        let sectionInfo = fetchedInfoController.sections[section]
        return numberOfRowsForSectionStyle(sectionInfo)
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        switch sectionInfo.style {
        case .Attribute:
            let key = sectionInfo.cellKeys![indexPath.row]
            return attributeCellForKey(key, atIndexPath: indexPath)
            
        case .ToOneRelationship(let toOneRelationshipKey):
            return toOneRelationshipCellForKey(toOneRelationshipKey, atIndexPath: indexPath)
            
        case .ToManyRelationship(let toManyRelationshipKey, let isOrderdBefore):
            return toManyRelationshipCellForKey(toManyRelationshipKey,
                isOrderdBefore: isOrderdBefore,
                editingStyles: sectionInfo.editingStyles,
                atIndexPath: indexPath)
        }
        
    }
    
   

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedInfoController.sections[section]
        return sectionInfo.identifier
    }
    
    private func numberOfRowsForSectionStyle(sectionInfo : SectionInfo) -> Int {
        switch sectionInfo.style {
        case .Attribute:
            return sectionInfo.cellKeys!.count
            
        case .ToOneRelationship(let toOneRelationshipKey):
            return detailItem.valueForKey(toOneRelationshipKey) != nil ? 1 : 0
            
        case .ToManyRelationship(let toManyRelationshipKey, _):
            let managedObjectSet = detailItem.mutableSetValueForKey(toManyRelationshipKey)
            if sectionInfo.editingStyles.contains(.Insert) && editing {
                // Editing mode and section can insert new cell, then show a insert style cell at bottom.
                return managedObjectSet.count + 1
            } else if managedObjectSet.count == 0 {
                // Show a empty style cell at bottom when the section is empty.
                return managedObjectSet.count + 1
            } else {
                // Normal case here.
                return managedObjectSet.count
            }
            
        }
    }
    
    private func attributeCellForKey(key: String, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let objectValue = ObjectValue(rootObject: detailItem, key: key)
        guard let identifier = cellReuseIdentifierFromItemKey(key) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! ObjectValueTableViewCell
        cell.objectValue = objectValue
        return cell
    }
    
    private func toOneRelationshipCellForKey(key: String, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellDetailItem = detailItem.valueForKey(key) as! RootObject
        guard let identifier = cellReuseIdentifierFromItemKey(key) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! RootObjectTableViewCell
        cell.detailItem = cellDetailItem
        return cell
    }
    
    private func toManyRelationshipCellForKey(
        key: String,
        isOrderdBefore: IsManagedObjectOrderedBefore,
        editingStyles: [SectionInfo.EditingStyle],
        atIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let managedObjectSet = detailItem.mutableSetValueForKey(key)
        if editingStyles.contains(.Insert) && editing {
            // Editing mode and section can insert new cell, then show a insert style cell at bottom.
            let destinationEntityName = detailItem.destinationEntityNameForRelationshipKey(key)!
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.InsertStyleCellReuseIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = "Add New \(destinationEntityName)."
            return cell
        } else if managedObjectSet.count == 0 {
            // Show a empty style cell at bottom when the section is empty.
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.EmptyStyleCellReuseIdentifier, forIndexPath: indexPath)
            return cell
        } else {
            // Normal case here.
            let managedObjects = (managedObjectSet.allObjects as! [RootObject]).sort(isOrderdBefore)
            let cellDetailItem = managedObjects[indexPath.row]
            guard let identifier = cellReuseIdentifierFromItemKey(key) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! RootObjectTableViewCell
            cell.detailItem = cellDetailItem
            return cell
        }
    }
    
    
    
    // MARK: - Table View Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        
        // When tap a cell which editingStyle is Insert, then do it.
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.editingStyle == .Insert {
            self.tableView(tableView, commitEditingStyle: cell.editingStyle, forRowAtIndexPath: indexPath)
        }
        
    }
    
    // MARK: - Table View Edited Method
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let editingStyle = self.tableView(tableView, editingStyleForRowAtIndexPath: indexPath)
        return editingStyle == .None ? false : true
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
        
        if sectionInfo.editingStyles.contains(.Insert) && sectionInfo.editingStyles.contains(.Delete) {
            // Can insert and delete object in section
            let matchInsertCondition: Bool = tableView.editing && (indexPath.row == numberOfRows - 1)
            return matchInsertCondition ? .Insert : .Delete
            
        } else if (sectionInfo.editingStyles.contains(.Insert)) {
            // Can only insert object in section
            let matchInsertCondition: Bool = tableView.editing && (indexPath.row == numberOfRows - 1)
            return matchInsertCondition ? .Insert : .None
            
        } else if (sectionInfo.editingStyles.contains(.Delete)) {
            // Can only delete object in section
            return .Delete
            
        } else {
            return .None
            
        }
        
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        tableView.beginUpdates()
        
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        switch sectionInfo.style {
        case .ToManyRelationship(let toManyRelationshipKey, let isManagedObjectOrderedBefore):
            commitEditingStyle(editingStyle, atIndexPath: indexPath, toManyRelationshipKey: toManyRelationshipKey, isManagedObjectOrderedBefore:isManagedObjectOrderedBefore)
            
        default: break
        }
        
        
        tableView.endUpdates()
    }
    
    private func commitEditingStyle(editingStyle: UITableViewCellEditingStyle, atIndexPath indexPath: NSIndexPath, toManyRelationshipKey: String, isManagedObjectOrderedBefore: IsManagedObjectOrderedBefore) {
        let destinationEntityName = detailItem.destinationEntityNameForRelationshipKey(toManyRelationshipKey)!
        let relationshipObjectSet = detailItem.mutableSetValueForKey(toManyRelationshipKey)
        
        switch editingStyle {
        case .Insert:
            let relationshipObject = RootObject.insertNewObjectForEntityForName(destinationEntityName)
            relationshipObjectSet.addObject(relationshipObject)
            let row: Int = detailItem.arrayForRelationshipKey(toManyRelationshipKey, isOrderedBefore: isManagedObjectOrderedBefore).indexOf(relationshipObject)!
            let relationshipObjectIndexPath = NSIndexPath(forRow: row, inSection: indexPath.section)
            tableView.insertRowsAtIndexPaths([relationshipObjectIndexPath], withRowAnimation: .Fade)
        case .Delete:
            let relationshipObject = (relationshipObjectSet.allObjects as! [RootObject])[indexPath.row]
            relationshipObjectSet.removeObject(relationshipObject)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        default: break
        }
    }
    
    // MARK: - Fetched Info Controller Data Source
    
    private struct Constants {
        static let AttributeSectionKey = "Attribute"
    }
    
    
    func identifiersForSectionInfos() -> [String] {
        if editing == false {
            // Public read
            var relationshipNames = detailItem.entity.relationshipsByName.keys.array
            relationshipNames.insert(Constants.AttributeSectionKey, atIndex: 0)
            return relationshipNames
        } else {
            // Private write
            return [Constants.AttributeSectionKey]
        }
        
    }
    
    func sectionInfoForIdentifier(identifier: String) -> SectionInfo {
        
        if editing == false {
            // Public read
            let style: SectionInfo.Style!
            var editingStyles: [SectionInfo.EditingStyle] = []
            
            if identifier == Constants.AttributeSectionKey {
                style = .Attribute
            } else {
                let relationshipDescription = detailItem.entity.relationshipsByName[identifier]!
                style = relationshipDescription.toMany ? .ToManyRelationship(identifier , < ) : .ToOneRelationship(identifier)
                if relationshipDescription.toMany { editingStyles = [.Insert, .Delete] }
            }
            
            return SectionInfo(identifier: identifier, style: style, editingStyles: editingStyles)
        } else {
            // Private write
            return SectionInfo(identifier: identifier, style: .Attribute, editingStyles: [])
        }
        
        
    }
    
    func cellKeysBySectionIdentifier(identifier: String) -> [String]? {
        return detailItem.entity.attributesByName.keys.array
    }
    
    func cellReuseIdentifierFromItemKey(key: String) -> String? {
        
        switch key {
        case "title", "body", "id":
            return Storyboard.TextCellReuseIdentifier
            
        case "creationDate", "modifyDate":
            return Storyboard.DateCellReuseIdentifier
            
        case "imageData":
            return Storyboard.ImageCellReuseIdentifier
        case "reviews", "usersLikeMe", "whoPost":
            return Storyboard.DetailItemCellReuseIdentifier
            
        default:
            return nil
            
        }
        
    }
    
    struct Storyboard {
        static let TableViewEstimatedRowHeight: CGFloat = 44
        
        static let EmptyStyleCellReuseIdentifier = "EmptyStyleCell"
        static let InsertStyleCellReuseIdentifier = "InsertStyleCell"
        static let NumberCellReuseIdentifier = "NumberCell"
        static let BoolCellReuseIdentifier = "BoolCell"
        static let TextCellReuseIdentifier = "TextCell"
        static let DateCellReuseIdentifier = "DateCell"
        static let ImageCellReuseIdentifier = "ImageCell"
        static let DetailItemCellReuseIdentifier = "DetailItemCell"
        
    }
    
    
    
}

enum DetailItemShowStyle {
    case AuthorInsert
    case AuthorRead
    case AuthorModify
    case PublicRead
}


