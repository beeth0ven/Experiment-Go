//
//  FetchedDataController.swift
//  Experiment Go
//
//  Created by luojie on 7/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocol Fetched Data Controller Delegate

protocol FetchedDataControllerDelegate: class {
    
    func controllerWillChangeContent(controller: FetchedDataController)
    
     func controller(controller: FetchedDataController,
        didChangeObjectAtIndexPath indexPath: NSIndexPath,
        forChangeType type: FetchedDataController.ChangeType
    )
    
    func controller(controller: FetchedDataController,
        didChangeSectionAtIndex sectionIndex: Int,
        forChangeType type: FetchedDataController.ChangeType
    )
    
    func controllerDidlChangeContent(controller: FetchedDataController)

}

 

class FetchedDataController {
    
    // MARK: - Properties

    var experiment: Experiment! {
        didSet {
            configureDataStruct()
        }
    }
    
    var sections: [SectionInfo]
    
    var editing: Bool = false {
        didSet {
            if editing != oldValue {
                toggleEditingMode(editing)
            }
        }
    }
    
    
    
    var isNewExperimentAdded = false

    
    weak var delegate: FetchedDataControllerDelegate?
    
    // MARK: - Init Method
    
    init(experiment: Experiment,sections: [SectionInfo], editing: Bool, isNewExperimentAdded: Bool) {
        self.sections = sections
        self.editing = editing
        self.experiment = experiment
        self.isNewExperimentAdded = isNewExperimentAdded
    }
    
    convenience init(experiment: Experiment, isNewExperimentAdded: Bool ) {
        self.init(experiment: experiment, sections: [], editing: false, isNewExperimentAdded: isNewExperimentAdded)
        configureDataStruct()
    }
    
    // MARK: - Manage Sections
    
    func sectionIndexForIdentifier(identifier: SectionInfo.Identifier) -> Int? {
        var sectionIndex: Int?
        for (index, sectionInfo) in sections.enumerate() {
            if sectionInfo.identifier == identifier {
                sectionIndex = index
                break
            }
        }
        return sectionIndex
    }
    
    func reloadSectionWithIdentifier(identifier: SectionInfo.Identifier) {
        guard let sectionIndex = sectionIndexForIdentifier(identifier) else { return }
        guard let sectionInfo = sectionInfoForIdentifier(identifier) else { return }
        
        let type: FetchedDataController.ChangeType = .Update
        didChangeSectionAtIndex(sectionIndex, forChangeType: type) {
            [unowned self] in
            self.sections.removeAtIndex(sectionIndex)
            self.sections.insert(sectionInfo, atIndex: sectionIndex)
        }
        
        
    }
    

    // MARK: - Manage Relationships
    
    func relationshipObjectAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject? {
        guard indexPath.section < sections.count else { return nil }
        let sectionInfo = sections[indexPath.section]
        let relationshipObjectSet = experiment.mutableSetValueForKey(sectionInfo.identifier.key)
        
        guard indexPath.row < relationshipObjectSet.count else { return nil }
        return relationshipObjectSet.allObjects[indexPath.row] as? NSManagedObject
    }
    
    func addRelationshipObject(managedObject: NSManagedObject, withSectionIdentifier identifier: SectionInfo.Identifier) {
        //Operate Core Data
        let relationshipObjectSet: NSMutableSet = experiment.mutableSetValueForKey(identifier.key)
        guard !relationshipObjectSet.containsObject(managedObject) else { return }
        relationshipObjectSet.addObject(managedObject)

        //Operate Fetched Data Controller and Table View
        guard let object = objectFromManagedObject(managedObject) else { return }
        guard let row: Int = (relationshipObjectSet.allObjects as! [NSManagedObject]).indexOf(managedObject)  else { return }
        guard let section: Int = sectionIndexForIdentifier(identifier) else { return }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        insertObect(object, atIndexPath: indexPath)
    }
    
    func removeRelationshipObject(managedObject: NSManagedObject, withSectionIdentifier identifier: SectionInfo.Identifier) {
        let relationshipObjectSet: NSMutableSet = experiment.mutableSetValueForKey(identifier.key)
        guard let section = sectionIndexForIdentifier(identifier) else { return }
        guard let row: Int = (relationshipObjectSet.allObjects as! [NSManagedObject]).indexOf(managedObject)  else { return }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        
        //Operate Core Data
        relationshipObjectSet.removeObject(managedObject)
        
        //Operate Fetched Data Controller and Table View
        removeObectAtIndexPath(indexPath)
        
    }
    
    func removeRelationshipObjectAtIndexPath(indexPath: NSIndexPath) {
        guard let managedObject = relationshipObjectAtIndexPath(indexPath) else { return }
        let identifier = sections[indexPath.section].identifier
        removeRelationshipObject(managedObject, withSectionIdentifier: identifier)
    }
    
    // MARK: - Manage SectionInfo

    private func sectionInfoForIdentifier(identifier: SectionInfo.Identifier) -> SectionInfo? {
        switch identifier {
        case .Properties:
            let titleObject = Object.TextField(Experiment.Constants.TitleKey, experiment.title)
            let bodyObject = Object.TextField(Experiment.Constants.BodyKey, experiment.body)
            return SectionInfo(identifier: identifier, objects: [titleObject, bodyObject], type: .Properties)
            
        case .Reviews:
            return sectionInfoFromRelationshipIdentifier(.Reviews, entityNameWhileEditing: Review.Constants.EntityNameKey)
            
        case .UsersLikeMe:
            return sectionInfoFromRelationshipIdentifier(.UsersLikeMe, entityNameWhileEditing: nil)
            
        case .UserActions:
            var buttonObject: Object?
            if experiment.whoPost! == User.currentUser() {
                if !isNewExperimentAdded { buttonObject = Object.Button(.Delete) }
            } else {
                var type: ButtonCellType =  .Like
                if let usersLikeMe = experiment.usersLikeMe?.allObjects as? [User] {
                    if usersLikeMe.contains(User.currentUser()) {
                        type = .Liking
                    }
                }
                buttonObject = Object.Button(type)
            }
            
            return buttonObject != nil ? SectionInfo(identifier: .UserActions, objects: [buttonObject!], type: .UserActions) : nil
        }
    }
    
    
    private func sectionInfoFromRelationshipIdentifier(identifier: SectionInfo.Identifier, entityNameWhileEditing entityNameKey: String?) -> SectionInfo {
        
        var objects: [Object] = []
        
        if let relationshipObjectSet = experiment.valueForKey(identifier.key) as? NSSet {
            if let managedObjects = relationshipObjectSet.allObjects as? [NSManagedObject] {
                objects = managedObjects.map { self.objectFromManagedObject($0)! }
            }
        }
        
        return SectionInfo(identifier: identifier, objects: objects, type: .Relationships(entityNameKey))
    }

    // MARK: - Manage Object
    
    func obectAtIndexPath(indexPath: NSIndexPath) -> Object? {
        return sections[indexPath.section].objects[indexPath.row]
    }
    
    
    private func insertObect(object: Object, atIndexPath indexPath: NSIndexPath) {
        let type: FetchedDataController.ChangeType = .Insert
        didChangeObjectAtIndexPath(indexPath, forChangeType: type) {
            [unowned self] in
            self.sections[indexPath.section].objects.insert(object, atIndex: indexPath.row)
        }
    }

    private func removeObectAtIndexPath(indexPath: NSIndexPath) {
        let type: FetchedDataController.ChangeType = .Delete
        didChangeObjectAtIndexPath(indexPath, forChangeType: type) {
            [unowned self] in
            self.sections[indexPath.section].objects.removeAtIndex(indexPath.row)
        }

    }
    
    private func didChangeObjectAtIndexPath(
        indexPath: NSIndexPath,
        forChangeType type: FetchedDataController.ChangeType,
        changes: (()->()) ) {
            delegate?.controllerWillChangeContent(self)
            changes()
            delegate?.controller(self,
                didChangeObjectAtIndexPath: indexPath,
                forChangeType: type)
            delegate?.controllerDidlChangeContent(self)

    }
    
    private func didChangeSectionAtIndex(
        sectionIndex: Int,
        forChangeType type: FetchedDataController.ChangeType,
        changes: (()->()) ) {
            delegate?.controllerWillChangeContent(self)
            changes()
            delegate?.controller(self,
                didChangeSectionAtIndex: sectionIndex,
                forChangeType: type)
            delegate?.controllerDidlChangeContent(self)
            
    }
    
    
    private func objectFromManagedObject(managedObject: NSManagedObject) -> Object? {
        var result:  Object? = nil
        if let review = managedObject as? Review {
            result = Object.RightDetail(review.whoReview!.name!, review.createDate!.description)
        } else if let user = managedObject as? User {
            result = Object.Basic(user.name!)
        }
        return result
    }
    
    
    // MARK: - Configure Data Struct

    private func configureDataStruct() {
        
        var result: [SectionInfo] = []
        for identifier in SectionInfo.Identifier.allIdentifiers {
            guard let sectionInfo = sectionInfoForIdentifier(identifier) else { continue }
            result.append(sectionInfo)
        }
   
        sections = result
        
    }
    
    
    private func toggleEditingMode(editing: Bool) {
        
        for (sectionIndex, section) in sections.enumerate() {
            switch section.type {
            case .Relationships(let entityNameKey):
                if entityNameKey?.characters.count > 0 {
                    var indexPath: NSIndexPath!
                    if editing {
                        let object = Object.Basic("Add New \(entityNameKey!).")
                        indexPath = NSIndexPath(forRow: section.objects.count, inSection: sectionIndex)
                        insertObect(object, atIndexPath: indexPath)
                    } else {
                        indexPath = NSIndexPath(forRow: section.objects.count - 1, inSection: sectionIndex)
                        removeObectAtIndexPath(indexPath)
                    }
                    
                }
            default: break
            }
            
        }
        
        reloadSectionWithIdentifier(.Properties)
        
    }

    
    // MARK: - Data Struct

     struct SectionInfo {
        var identifier: Identifier
        var objects: [Object]
        var type: Type
        

        
        init(identifier: Identifier, objects: [Object], type: Type) {
            self.identifier = identifier
            self.objects = objects
            self.type = type
        }
        
        var indexTitle: String {
            return String(identifier.key.characters.first).uppercaseString
        }
        
        var numberOfObjects: Int {
            return objects.count
        }
        

        enum Type {
            case Properties
            // RelationShips's param (String?) stand for the entity to add while editing mode at section bottom.
            case Relationships(String?)
            case UserActions
            
        }
        
        enum Identifier {
            case Properties
            case Reviews
            case UsersLikeMe
            case UserActions
            
            var key: String {
                switch self {
                case .Properties:
                    return Experiment.Constants.AttributeKey
                case .Reviews:
                    return Experiment.Constants.ReviewsKey
                case .UsersLikeMe:
                    return Experiment.Constants.UsersLikeMeKey
                case .UserActions:
                    return "UserActionsKey"
                }
                
            }
            
            static var allIdentifiers: [Identifier] {
                return [
                    .Properties,
                    .Reviews,
                    .UsersLikeMe,
                    .UserActions
                ]
            }
        }
        
    }
    
    enum Object {
        
        private struct Storyboard {
            static let BasicCellReuseIdentifier = "BasicCell"
            static let RightDetailReuseIdentifier = "RightDetailCell"
            static let TextFieldCellReuseIdentifier = "TextFieldCell"
            static let ButtonCellReuseIdentifier = "ButtonCell"
        }
        
        case Basic(String)
        case RightDetail(String, String)
        case TextField(String, String?)
        case Button(ButtonCellType)
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return Storyboard.BasicCellReuseIdentifier
            case .RightDetail(_, _):
                return Storyboard.RightDetailReuseIdentifier
            case .TextField(_, _):
                return Storyboard.TextFieldCellReuseIdentifier
            case .Button(_):
                return Storyboard.ButtonCellReuseIdentifier
            }
        }
    }

    
    enum ButtonCellType: CustomStringConvertible{
        
        case Delete
        case Like
        case Liking
        
        var preferedColor: UIColor {
            switch self {
            case Delete:
                return UIColor.flatRedColor()
            case Like:
                return UIColor.flatSandColor()
            case Liking:
                return UIColor.flatSandColorDark()
            }
        }
        
        var description: String {
            switch self {
            case Delete:
                return "Delete"
            case Like:
                return "Like"
            case Liking:
                return "Liking"
            }
        }
    }
    
    enum ChangeType {
        case Insert
        case Delete
        case Update
    }
    

}


