//
//  Root.swift
//  Experiment Go
//
//  Created by luojie on 7/17/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

//@objc(Root)
class RootObject: NSManagedObject, Comparable {
    
    // Insert code here to add functionality to your managed object subclass
    struct Constants {
        static let DefaultSortKey = CloudManager.Constants.CreationDateKey
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = NSDate()
        recordID = NSUUID().UUIDString
    }
    
    func descriptionForKeyPath(keyPath: String) -> String {
        return (valueForKeyPath(keyPath) as? CustomStringConvertible)?.description ?? ""
    }
    
    func destinationEntityNameForRelationshipKey(key: String) -> String? {
        let relationshipDescription = self.entity.relationshipsByName[key]
        return relationshipDescription?.destinationEntity?.name
    }
    
    class func insertNewObjectForEntityForName(entityName: String) -> RootObject {
        let context = NSManagedObjectContext.defaultContext()
        return  NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! RootObject
    }
    
}

func ==(rootObject0: RootObject, rootObject1: RootObject) -> Bool { return rootObject0.creationDate == rootObject1.creationDate }
func <(rootObject0: RootObject, rootObject1: RootObject) -> Bool { return rootObject0.creationDate < rootObject1.creationDate }

class ObjectValue {
    var rootObject: RootObject
    var key: String
    
    var attributeType: NSAttributeType?  {
        let attributesByName = rootObject.entity.attributesByName
        let attributeDescription = attributesByName[key]
        return attributeDescription?.attributeType
    }
    
    init(rootObject: RootObject, key: String){
        self.rootObject = rootObject
        self.key = key
    }
    
    var value: AnyObject? {
        get {
            return rootObject.valueForKey(key)
        }
            
        set {
            rootObject.setValue(newValue, forKey: key)
        }
    }
    
    var image: UIImage? {
        get {
            guard attributeType != nil else { return nil }
            switch attributeType! {
            case .BinaryDataAttributeType:
                guard let data = value as? NSData else { return nil }
                return UIImage(data: data)
            default: return nil
            }
        }
        
        set {
            guard attributeType != nil else { return value = nil }
            guard newValue != nil else { return value = nil }
            switch attributeType! {
            case .BinaryDataAttributeType:
                value = UIImageJPEGRepresentation(newValue!, 1.0)
            default: value = nil
            }
        }
    }
    

}

extension RootObject: CloudSupport{
    
    class func objectWithRecordID(recordID: String, entityName: String) -> RootObject? {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "recordID = %@", recordID)
        
        var matches: [AnyObject]
        do {
            try matches = NSManagedObjectContext.defaultContext().executeFetchRequest(fetchRequest)
        } catch {
            abort()
        }
        
        if matches.count == 1 {
             return matches.first as? RootObject
        } else if matches.count == 0 {
            return nil
        } else {
            // error
            abort()
        }
    }
    
    func saveNewObjectFromRecord(record: CKRecord) {
        let id = record.recordID.recordName
        setValue(id, forKey: CloudManager.Constants.RecordIDKey)
        configFromRecord(record)
    }
    
    func saveNewRecordToCloud(completionHandler: (CKRecord?, NSError?) -> Void) {
        guard inserted else { return print("managed object \(entity.name!) is not new.") }
        let recordID = CKRecordID(recordName: self.recordID!)
        let record = CKRecord(recordType: "Event", recordID: recordID)
        configToRecord(record)
        let context = NSManagedObjectContext.cloudPublicContext()
        context.saveRecord(record, completionHandler: completionHandler)
    }
    
    func readRecordFormCloud(completionHandler: (CKRecord?, NSError?) -> Void) {
        let recordID = CKRecordID(recordName: self.recordID!)
        let context = NSManagedObjectContext.cloudPublicContext()
        context.fetchRecordWithID(recordID, completionHandler: completionHandler)
    }
    
    func updateRecordToCloud(completionHandler: (CKRecord?, NSError?) -> Void) {
        readRecordFormCloud { (record, error) -> Void in
            if error == nil {
                self.configToRecord(record!)
                let context = NSManagedObjectContext.cloudPublicContext()
                context.saveRecord(record!, completionHandler: completionHandler)
            } else {
                print("Failed to Read record from cloud.")
            }
        }
    }
    
    func updateRecordFromCloud(completionHandler: (CKRecord?, NSError?) -> Void) {
        readRecordFormCloud { (record, error) -> Void in
            if error == nil {
                self.configFromRecord(record!)
            } else {
                print("Failed to Read record from cloud.")
            }
            completionHandler(record, error)
        }
    }
    
    func deleteRecordFormCloud(completionHandler: (CKRecordID?, NSError?) -> Void) {
        let recordID = CKRecordID(recordName: self.recordID!)
        let context = NSManagedObjectContext.cloudPublicContext()
        context.deleteRecordWithID(recordID, completionHandler: completionHandler)
    }
    
    func configToRecord(record: CKRecord) {
//        record.setValue(timeStamp, forKey: "timeStamp")
//        record.setValue(name, forKey: "name")
    }
    
    func configFromRecord(record: CKRecord) {
        
        
//        timeStamp = record.valueForKey("timeStamp") as? NSDate
//        name = record.valueForKey("name") as? String
    }
    
}


