//
//  SectionManager.swift
//  Experiment Go
//
//  Created by luojie on 7/26/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

// FetchedInfoController provide a data structure for the table view controller which has a managed object as model,
// FetchedInfoController plays like fetched result controller.

import Foundation
import CoreData

class SectionManager {
    var identifier: String
    var style: Style 
    
    var content: SectionContent
    
    required init(identifier: String, style: Style, content: SectionContent) {
        self.identifier = identifier
        self.style = style
        self.content = content
        
    }
    
    enum Style {
        case Attribute
        case ToOneRelationship
        case ToManyRelationship
    }
    
    enum SectionContent {
        case Keys([String])
        case FetchResultController(FetchedRelationshipController)
    }
}

class FetchedRelationshipController: NSFetchedResultsController {
    var relationshipKey: String
    var rootObject: RootObject
    var sortDescriptors: [NSSortDescriptor]?
    
    convenience init(rootObject: RootObject, relationshipKey: String, sortDescriptors: [NSSortDescriptor]? ) {
        let fetchRequest = NSFetchRequest(rootObject: rootObject, relationshipKey: relationshipKey, sortDescriptors: sortDescriptors)
        self.init(rootObject: rootObject,
            relationshipKey: relationshipKey,
            fetchRequest: fetchRequest,
            managedObjectContext: NSManagedObjectContext.defaultContext(),
            sectionNameKeyPath: nil,
            cacheName: nil)
        
    }
    
    init(rootObject: RootObject,
        relationshipKey: String,
        fetchRequest: NSFetchRequest,
        managedObjectContext context: NSManagedObjectContext,
        sectionNameKeyPath: String?,
        cacheName name: String?) {
            
            self.rootObject = rootObject
            self.relationshipKey = relationshipKey
            super.init(fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: sectionNameKeyPath,
                cacheName: name)
    }
    
    
}

extension NSFetchRequest {
    convenience init(rootObject: RootObject, relationshipKey: String ,sortDescriptors: [NSSortDescriptor]?) {
        let entity = rootObject.entity
        let relationshipsByName = entity.relationshipsByName
        let relationshipDescription = relationshipsByName[relationshipKey]!
        let destinationEntity = relationshipDescription.destinationEntity!
        let destinationEntityName = destinationEntity.name!
        
        let inverseRelationship = relationshipDescription.inverseRelationship!
        let destinationRelationshipName = inverseRelationship.name
        
        let inverseRelationshipToMany = inverseRelationship.toMany
        
        let predicate: NSPredicate
        if inverseRelationshipToMany == false {
            // To one relation ship
            predicate = NSPredicate(format: "%K = %@", destinationRelationshipName ,rootObject)
        } else {
            // To many relation ship/
            predicate = NSPredicate(format: "ANY %K = %@", destinationRelationshipName ,rootObject)
        }
        
        self.init(entityName: destinationEntityName)
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }
}



enum DetailItemShowStyle {
    case AuthorInsert
    case AuthorRead
    case AuthorModify
    case PublicRead
}

// MARK: - User Actions

//    override func setEditing(editing: Bool, animated: Bool) {
//        if self.editing != editing {
//            super.setEditing(editing, animated: true)
//            tableView.setEditing(editing, animated: true)
//            // Toggle Editing Mode Only when the detailItem is not new one.
//            if detailItem.inserted == false { toggleEditingMode(editing) }
//        }
//    }

//    private func toggleEditingMode(editing: Bool) {
//        let options: UIViewAnimationOptions = editing ? .TransitionCurlUp : .TransitionCurlDown
//        UIView.transitionWithView(navigationController!.view,
//            duration: 0.4,
//            options: options,
//            animations: {
//                self.fetchedInfoController.reloadDataStruct()
//                self.configureBarButtons()
//                self.tableView.reloadData()
//            },
//            completion: nil)
//    }

// MARK: - Help Method
//
//    func addObject(rootObject: RootObject, forToManyRelationshipKey key: String) -> Bool {
//        let sectionInfo = sectionInfoForIdentifier(key)
//        guard case .ToManyRelationship(let key,let isOrderdBefore) = sectionInfo.style else { return false }
//        let relationshipSet = detailItem!.mutableSetValueForKey(key)
//
//        guard relationshipSet.containsObject(rootObject) == false else { return false }
//        guard detailItem.destinationEntityNameForRelationshipKey(key) == rootObject.entity.name else { return false }
//        relationshipSet.addObject(rootObject)
//
//        let relationshipAsArray = (relationshipSet.allObjects as! [RootObject]).sort(isOrderdBefore)
//        guard
//            let row: Int = relationshipAsArray.indexOf(rootObject),
//            let section: Int = identifiersForSectionInfos().indexOf(key)
//            else { return false }
//
//        let indexPath = NSIndexPath(forRow: row, inSection: section)
//        tableView.beginUpdates()
//        if detailItem.mutableSetValueForKey(key).count == 1 {
//            // Empty Cell Change to Normal Cell
//            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else {
//            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        }
//        tableView.endUpdates()
//        return true
//    }
//
//    func removeObject(rootObject: RootObject, forToManyRelationshipKey key: String) -> Bool {
//
//        let sectionInfo = sectionInfoForIdentifier(key)
//        guard case .ToManyRelationship(let key,let isOrderdBefore) = sectionInfo.style else { return false }
//        let relationshipSet = detailItem!.mutableSetValueForKey(key)
//
//        guard relationshipSet.containsObject(rootObject) == true else { return false }
//
//        let relationshipAsArray = (relationshipSet.allObjects as! [RootObject]).sort(isOrderdBefore)
//        guard
//            let row: Int = relationshipAsArray.indexOf(rootObject),
//            let section: Int = identifiersForSectionInfos().indexOf(key)
//            else { return false }
//        let indexPath = NSIndexPath(forRow: row, inSection: section)
//
//        relationshipSet.removeObject(rootObject)
//
//        tableView.beginUpdates()
//        if detailItem.mutableSetValueForKey(key).count == 0 {
//            // Normal Cell Change to Empty Cell
//            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else {
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        }
//        tableView.endUpdates()
//
//        return true
//
//    }



// MARK: - Table View Delegate

//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//
//        tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
//
//        // When tap a cell which editingStyle is Insert, then do it.
//        let cell = tableView.cellForRowAtIndexPath(indexPath)!
//        if cell.editingStyle == .Insert {
//            self.tableView(tableView, commitEditingStyle: cell.editingStyle, forRowAtIndexPath: indexPath)
//        }
//
//    }

// MARK: - Table View Edited Method
//
//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        let editingStyle = self.tableView(tableView, editingStyleForRowAtIndexPath: indexPath)
//        return editingStyle == .None ? false : true
//    }
//
//
//    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        let sectionInfo = fetchedInfoController.sections[indexPath.section]
//        let numberOfRows = tableView.numberOfRowsInSection(indexPath.section)
//
//        if sectionInfo.editingStyles.contains(.Insert) && sectionInfo.editingStyles.contains(.Delete) {
//            // Can insert and delete object in section
//            let matchInsertCondition: Bool = tableView.editing && (indexPath.row == numberOfRows - 1)
//            return matchInsertCondition ? .Insert : .Delete
//
//        } else if (sectionInfo.editingStyles.contains(.Insert)) {
//            // Can only insert object in section
//            let matchInsertCondition: Bool = tableView.editing && (indexPath.row == numberOfRows - 1)
//            return matchInsertCondition ? .Insert : .None
//
//        } else if (sectionInfo.editingStyles.contains(.Delete)) {
//            // Can only delete object in section
//            return .Delete
//
//        } else {
//            return .None
//
//        }
//
//    }
//
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.beginUpdates()
//
//        let sectionInfo = fetchedInfoController.sections[indexPath.section]
//        switch sectionInfo.style {
//        case .ToManyRelationship(let toManyRelationshipKey, let isManagedObjectOrderedBefore):
//            commitEditingStyle(editingStyle, atIndexPath: indexPath, toManyRelationshipKey: toManyRelationshipKey, isManagedObjectOrderedBefore:isManagedObjectOrderedBefore)
//
//        default: break
//        }
//
//
//        tableView.endUpdates()
//    }

//    private func commitEditingStyle(editingStyle: UITableViewCellEditingStyle, atIndexPath indexPath: NSIndexPath, toManyRelationshipKey: String, isManagedObjectOrderedBefore: IsManagedObjectOrderedBefore) {
//        let destinationEntityName = detailItem.destinationEntityNameForRelationshipKey(toManyRelationshipKey)!
//        let relationshipObjectSet = detailItem.mutableSetValueForKey(toManyRelationshipKey)
//
//        switch editingStyle {
//        case .Insert:
//            let relationshipObject = RootObject.insertNewObjectForEntityForName(destinationEntityName)
//            relationshipObjectSet.addObject(relationshipObject)
//            let row: Int = detailItem.arrayForRelationshipKey(toManyRelationshipKey, isOrderedBefore: isManagedObjectOrderedBefore).indexOf(relationshipObject)!
//            let relationshipObjectIndexPath = NSIndexPath(forRow: row, inSection: indexPath.section)
//            tableView.insertRowsAtIndexPaths([relationshipObjectIndexPath], withRowAnimation: .Fade)
//        case .Delete:
//            let relationshipObject = (relationshipObjectSet.allObjects as! [RootObject])[indexPath.row]
//            relationshipObjectSet.removeObject(relationshipObject)
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        default: break
//        }
//    }




