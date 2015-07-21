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
    
    var editing: Bool {
        didSet {
            if editing != oldValue {
                toggleEditingMode(editing)
            }
        }
    }
    
    weak var delegate: FetchedDataControllerDelegate?
    
    // MARK: - Init Method
    
    init(experiment: Experiment, sections: [SectionInfo], editing: Bool) {
        self.sections = sections
        self.editing = editing
        self.experiment = experiment
    }
    
    convenience init(experiment: Experiment) {
        self.init(experiment: experiment, sections: [], editing: false)
        configureDataStruct()
    }
    
    // MARK: - Public Method

    
    func obectAtIndexPath(indexPath: NSIndexPath) -> Object? {
        return sections[indexPath.section].objects[indexPath.row]
    }
    
    
    func relationshipObjectAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject? {
        guard indexPath.section < sections.count else { return nil }
        let sectionInfo = sections[indexPath.section]
        let sectionName = sectionInfo.name
        let relationshipObjectSet = experiment.mutableSetValueForKey(sectionName)
        guard indexPath.row < relationshipObjectSet.count else { return nil }
        return relationshipObjectSet.allObjects[indexPath.row] as? NSManagedObject
    }
    
    func addRelationshipObject(managedObject: NSManagedObject, inSection section: Int) {
        guard section < sections.count else { return }
        //Operate Core Data
        let sectionInfo = sections[section]
        let sectionName = sectionInfo.name
        let relationshipObjectSet: NSMutableSet = experiment.mutableSetValueForKey(sectionName)
        relationshipObjectSet.addObject(managedObject)
        
        //Operate Fetched Data Controller and Table View
        guard let object = objectFromManagedObject(managedObject) else { return }
        guard let row: Int = (relationshipObjectSet.allObjects as! [NSManagedObject]).indexOf(managedObject)  else { return }
        let indexPath = NSIndexPath(forRow: row, inSection: section)
        insertObect(object, atIndexPath: indexPath)
    }
    
    func removeRelationshipObjectAtIndexPath(indexPath: NSIndexPath) {
        guard indexPath.section < sections.count else { return }
        let sectionInfo = sections[indexPath.section]
        let sectionName = sectionInfo.name
        let relationshipObjectSet = experiment.mutableSetValueForKey(sectionName)
        
        guard indexPath.row < relationshipObjectSet.count else { return }
        //Operate Fetched Data Controller and Table View
        removeObectAtIndexPath(indexPath)
        
        //Operate Core Data
        let managedObject = relationshipObjectSet.allObjects[indexPath.row] as! NSManagedObject
        relationshipObjectSet.removeObject(managedObject)
        
        
    }
    
    
    // MARK: - Private Method
  
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
    
    private func configureDataStruct() {
        
        var result: [SectionInfo] = []
        // Section 0: Property
        let titleObject = Object.TextField(Experiment.Constants.TitleKey, experiment.title)
        let bodyObject = Object.TextField(Experiment.Constants.BodyKey, experiment.body)
        let propertySectionInfo = SectionInfo(name: Experiment.Constants.PropertyKey, objects: [titleObject, bodyObject], type: .Properties)
        result.append(propertySectionInfo)
        
        // Section 1: Reviews
        
        let reviewsSectionInfo = sectionInfoFromRelationshipName(Experiment.Constants.ReviewsKey, entityNameWhileEditing: Review.Constants.EntityNameKey)
        result.append(reviewsSectionInfo)
        
        
        // Section 2: UsersLikeMe
        let usersLikeMeSectionInfo = sectionInfoFromRelationshipName(Experiment.Constants.UsersLikeMeKey, entityNameWhileEditing: nil)
        result.append(usersLikeMeSectionInfo)
        
        // Section 3: User Actions - Delete, Like Or UnLike
        var buttonObject: Object!
        if experiment.whoPost! == User.currentUser() {
            buttonObject = Object.Button(.Delete)
        } else {
            var type: ButtonCellType =  .UnLike
            if let usersLikeMe = experiment.usersLikeMe?.allObjects as? [User] {
                if usersLikeMe.contains(User.currentUser()) {
                    type = .Like
                }
            }
            buttonObject = Object.Button(type)
        }
        
        let userActionSectionInfo = SectionInfo(name: Experiment.Constants.UserActionsKey, objects: [buttonObject], type: .UserActions)
        result.append(userActionSectionInfo)
        
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
        
    }


    private func sectionInfoFromRelationshipName(name: String, entityNameWhileEditing entityNameKey: String?) -> SectionInfo {
    
        var objects: [Object] = []

        if let relationshipObjectSet = experiment.valueForKey(name) as? NSSet {
            if let managedObjects = relationshipObjectSet.allObjects as? [NSManagedObject] {
                objects = managedObjects.map { self.objectFromManagedObject($0)! }
            }
        }

        return SectionInfo(name: name, objects: objects, type: .Relationships(entityNameKey))
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
    
    
        // MARK: - Data Struct

     struct SectionInfo {
        var name: String
        var objects: [Object]
        var type: Type
        
        init(name: String, objects: [Object], type: Type) {
            self.name = name
            self.objects = objects
            self.type = type
        }
        

        
        var indexTitle: String {
            return String(name.characters.first).uppercaseString
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
        case UnLike
        
        var preferedColor: UIColor {
            switch self {
            case Delete:
                return UIColor.flatRedColor()
            case Like:
                return UIColor.flatSandColorDark()
            case UnLike:
                return UIColor.flatSandColor()
            }
        }
        
        var description: String {
            switch self {
            case Delete:
                return "Delete"
            case Like:
                return "Like"
            case UnLike:
                return "UnLike"
            }
        }
    }
    
    
    enum ChangeType {
        case Insert
        case Delete
    }
    

}

