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
    
    var detailItem: RootObect! {
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
            toggleEditingMode(editing)
            tableView.setEditing(editing, animated: true)
        }
    }
    
    private func toggleEditingMode(editing: Bool) {
        tableView.beginUpdates()
        
        for (sectionIndex, sectionInfo) in fetchedInfoController.sections.enumerate() {
            switch sectionInfo.style {
            case .ToManyRelationship(_):
                guard sectionInfo.editingStyles.contains(.Insert) else { continue }
                var indexPath: NSIndexPath!
                let objectsCount = detailItem.mutableSetValueForKey(sectionInfo.key).count
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
            self.editing = true
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
            
        case .ToManyRelationship(let toManyRelationshipKey, _):
            let managedObjectSet = detailItem.mutableSetValueForKey(toManyRelationshipKey)
            return (sectionInfo.editingStyles.contains(.Insert) && editing) ?  managedObjectSet.count + 1 : managedObjectSet.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let objectToConfigureCell = objectToConfigureCellAtIndexPath(indexPath) else {
            // Only happen, when the section last row show insertStyle at bottom while editing mode.
            guard let cellInfo = fetchedInfoController.cellInfoForInsertStyleAtIndexPath(indexPath) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.style.cellReuseIdentifier, forIndexPath: indexPath)
            let configureCellUseObect = cellInfo.style.configureCellUseObect
            configureCellUseObect(cell, detailItem)
            return cell
        }
        guard let cellInfo = fetchedInfoController.cellInfoAtIndexPath(indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.style.cellReuseIdentifier, forIndexPath: indexPath)
        let configureCellUseObect = cellInfo.style.configureCellUseObect
        configureCellUseObect(cell, objectToConfigureCell)
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
    
    private func objectToConfigureCellAtIndexPath(indexPath: NSIndexPath) -> RootObect? {
        let sectionInfo = fetchedInfoController.sections[indexPath.section]
        switch sectionInfo.style {
        case .Attribute:
            return detailItem
            
        case .ToOneRelationship(let toOneRelationshipKey):
            return detailItem.valueForKey(toOneRelationshipKey) as? RootObect
            
            
        case .ToManyRelationship(let toManyRelationshipKey, let isManagedObjectOrderedBefore):
            let managedObjects = (detailItem.mutableSetValueForKey(toManyRelationshipKey).allObjects as! [RootObect]).sort(isManagedObjectOrderedBefore)
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
            let relationshipObject = RootObect.insertNewObjectForEntityForName(destinationEntityName)
            relationshipObjectSet.addObject(relationshipObject)
            let row: Int = detailItem.arrayForRelationshipKey(toManyRelationshipKey, isOrderedBefore: isManagedObjectOrderedBefore).indexOf(relationshipObject)!
            let relationshipObjectIndexPath = NSIndexPath(forRow: row, inSection: indexPath.section)
            tableView.insertRowsAtIndexPaths([relationshipObjectIndexPath], withRowAnimation: .Fade)
        case .Delete:
            let relationshipObject = (relationshipObjectSet.allObjects as! [RootObect])[indexPath.row]
            relationshipObjectSet.removeObject(relationshipObject)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        default: break
        }
    }
}


extension DetailViewController: FetchedInfoControllerDataSource {
    
    private struct Constants {
        static let AttributeSectionKey = "Attribute"
    }
    
    
    struct ConfigCellOperationName {
        static let Default = "Default"
    }
    
    
    var knownCellStyle: Dictionary<String, CellInfo.Style> {
        get {
            var result = Dictionary<String, CellInfo.Style>()
            
            result[ConfigCellOperationName.Default] = CellInfo.Style.RightDetail {
                (cell, managedObject) in
                cell.textLabel?.text = managedObject.entity.name
                cell.detailTextLabel?.text = managedObject.descriptionForKeyPath(RootObect.Constants.CreateDateKey)
            }
            
            
            return result
        }
    }
    
    func keysForSectionInfos() -> [String] {
        var relationshipNames = detailItem.entity.relationshipsByName.keys.array
        relationshipNames.insert(Constants.AttributeSectionKey, atIndex: 0)
        return relationshipNames
    }
    
    func sectionInfoForKey(key: String) -> SectionInfo {
        let style: SectionInfo.Style!
        var editingStyles: [SectionInfo.EditingStyle] = []
        
        if key == Constants.AttributeSectionKey {
            style = .Attribute
        } else {
            let relationshipDescription = detailItem.entity.relationshipsByName[key]!
            style = relationshipDescription.toMany ? .ToManyRelationship(key , < ) : .ToOneRelationship(key)
            if relationshipDescription.toMany { editingStyles = [.Insert, .Delete] }
        }
        
        return SectionInfo(key: key, style: style, editingStyles: editingStyles)
    }
    
    
    func keysForCellInfosBySectionInfo(sectionInfo: SectionInfo) -> [String] {
        switch sectionInfo.style {
        case .Attribute:
            return detailItem.entity.attributesByName.keys.array
            
        case .ToOneRelationship(let toOneRelationshipName):
            return [detailItem.destinationEntityNameForRelationshipKey(toOneRelationshipName)!]
            
        case .ToManyRelationship(let toManyRelationshipName, _):
            var keys = [detailItem.destinationEntityNameForRelationshipKey(toManyRelationshipName)!]
            if sectionInfo.editingStyles.contains(.Insert) { keys.append(FetchedInfoController.Constants.InsertStyleKey) }
            
            return  keys
        }
    }
    
    func cellInfoForKey(key: String, bySectionInfo sectionInfo: SectionInfo) -> CellInfo {
        let style: CellInfo.Style!
        switch sectionInfo.style {
        case .Attribute:
            style = CellInfo.Style.TextField {
                (cell, managedObject) in
                guard let textFieldCell = cell as? TextFieldTableViewCell else { return }
                textFieldCell.detailItem = managedObject
                textFieldCell.stringKey = key
            }

            
//                .RightDetail {
//                (cell, managedObject) in
//                cell.textLabel?.text = key
//                cell.detailTextLabel?.text = managedObject.descriptionForKeyPath(key)
//            }
            
        case .ToOneRelationship(_):
            style = knownCellStyle[ConfigCellOperationName.Default]
            
        case .ToManyRelationship(_):
            if key != FetchedInfoController.Constants.InsertStyleKey {
                // Normal Cell Configure
                style = knownCellStyle[ConfigCellOperationName.Default]
            } else {
                // Insert Editing Style Cell Configure
                style = CellInfo.Style.Basic {
                    (cell, managedObject) in
                    let entityName = managedObject.destinationEntityNameForRelationshipKey(sectionInfo.key)!
                    cell.textLabel?.text = "Add New \(entityName)."
                }
            }
            
            
            
        }
        return CellInfo(key: key, style: style)
    }
}



