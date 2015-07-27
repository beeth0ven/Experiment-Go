//
//  Root.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

//@objc(Root)
class RootObect: NSManagedObject, Comparable {
    
    // Insert code here to add functionality to your managed object subclass
    
    
    struct Constants {
        static let DefaultSortKey = "createDate"
        static let CreateDateKey = "createDate"
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        createDate = NSDate()
        id = createDate?.timeIntervalSinceReferenceDate.description
    }
    
    func arrayForRelationshipKey(key: String, isOrderedBefore: IsManagedObjectOrderedBefore) -> [RootObect] {
        let managedObjectSet = self.mutableSetValueForKey(key)
        let managedObjects = managedObjectSet.allObjects as! [RootObect]
        return managedObjects.sort(isOrderedBefore)
    }
    
    
    func descriptionForKeyPath(keyPath: String) -> String {
        return (valueForKeyPath(keyPath) as? CustomStringConvertible)?.description ?? ""
    }
    
    func destinationEntityNameForRelationshipKey(key: String) -> String? {
        let relationshipDescription = self.entity.relationshipsByName[key]
        return relationshipDescription?.destinationEntity?.name
    }
    
    class func insertNewObjectForEntityForName(entityName: String) -> RootObect {
        let context = NSManagedObjectContext.defaultContext()
        return  NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! RootObect
    }

}

func ==(rootObject0: RootObect, rootObject1: RootObect) -> Bool { return rootObject0.createDate == rootObject1.createDate }
func <(rootObject0: RootObect, rootObject1: RootObect) -> Bool { return rootObject0.createDate < rootObject1.createDate }

