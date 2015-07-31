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
class RootObject: NSManagedObject, Comparable {
    
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
    
    func arrayForRelationshipKey(key: String, isOrderedBefore: IsManagedObjectOrderedBefore) -> [RootObject] {
        let managedObjectSet = self.mutableSetValueForKey(key)
        let managedObjects = managedObjectSet.allObjects as! [RootObject]
        return managedObjects.sort(isOrderedBefore)
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
    
//    func objectValueForKey(key: String) -> ObectValue? {
//        let attributesByName = entity.attributesByName
//        let relationshipsByName = entity.relationshipsByName
//        if let attributeDescription = attributesByName[key] {
//            return objectValueForKey(key, attributeType: attributeDescription.attributeType)
//            
//        } else if let relationshipDescription = relationshipsByName[key] {
//            return relationshipDescription.toMany ? .ToManyRelationshipValue(self, key) : .ToOneRelationshipValue(self, key)
//            
//        } else {
//            return nil
//        }
//    }
//    
//    func objectValueForKey(key: String,attributeType : NSAttributeType) -> ObectValue? {
//        switch attributeType {
//        case .Integer16AttributeType:
//            return .IntValue(self, key)
//        case .Integer32AttributeType:
//            return .IntValue(self, key)
//        case .Integer64AttributeType:
//            return .IntValue(self, key)
//            
//        case .DecimalAttributeType:
//            return .FloatValue(self, key)
//        case .FloatAttributeType:
//            return .FloatValue(self, key)
//        case .DoubleAttributeType:
//            return .DoubleValue(self, key)
//            
//            
//        case .BooleanAttributeType:
//            return .BoolValue(self, key)
//        case .StringAttributeType:
//            return .StingValue(self, key)
//        case .DateAttributeType:
//            return .DateValue(self, key)
//        case .BinaryDataAttributeType:
//            return .DataValue(self, key)
//        default:
//            return nil
//        }
//    }
    
}

func ==(rootObject0: RootObject, rootObject1: RootObject) -> Bool { return rootObject0.createDate == rootObject1.createDate }
func <(rootObject0: RootObject, rootObject1: RootObject) -> Bool { return rootObject0.createDate < rootObject1.createDate }

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

//enum bectValue: CustomStringConvertible {
//    
//    case IntValue(RootObect, String)
//    case FloatValue(RootObect, String)
//    case DoubleValue(RootObect, String)
//    case BoolValue(RootObect, String)
//    case StingValue(RootObect, String)
//    case DateValue(RootObect, String)
//    case DataValue(RootObect, String)
//    case ToOneRelationshipValue(RootObect, String)
//    case ToManyRelationshipValue(RootObect, String)
//    
//    
//
//    
//    var value: AnyObject? {
//        get {
//            switch self {
//                
//            case .IntValue(let object, let key):
//                return (object.valueForKey(key) as? NSNumber)?.integerValue
//            case .FloatValue(let object, let key):
//                return (object.valueForKey(key) as? NSNumber)?.floatValue
//            case .DoubleValue(let object, let key):
//                return (object.valueForKey(key) as? NSNumber)?.doubleValue
//            case .BoolValue(let object, let key):
//                return (object.valueForKey(key) as? NSNumber)?.boolValue
//            case .StingValue(let object, let key):
//                return object.valueForKey(key) as? String
//            case .DateValue(let object, let key):
//                return object.valueForKey(key) as? NSDate
//            case .DataValue(let object, let key):
//                return object.valueForKey(key) as? NSData
//
//            case .ToOneRelationshipValue(let object, let key):
//                return object.valueForKey(key) as? RootObect
//            case .ToManyRelationshipValue(let object, let key):
//                return object.mutableSetValueForKey(key)
//                
//            }
//        }
//        
//        set {
//            switch self {
//                
//            case .IntValue(let object, let key):
//                guard let integerValue = newValue as? Int else { return object.setValue(nil, forKey: key) }
//                object.setValue(NSNumber(integer: integerValue), forKey: key)
//                
//            case .FloatValue(let object, let key):
//                guard let floatValue = newValue as? Float else { return object.setValue(nil, forKey: key) }
//                object.setValue(NSNumber(float: floatValue), forKey: key)
//                
//            case .DoubleValue(let object, let key):
//                guard let doubleValue = newValue as? Double else { return object.setValue(nil, forKey: key) }
//                object.setValue(NSNumber(double: doubleValue), forKey: key)
//                
//            case .BoolValue(let object, let key):
//                guard let boolValue = newValue as? Bool else { return object.setValue(nil, forKey: key) }
//                object.setValue(NSNumber(bool: boolValue), forKey: key)
//                
//            case .StingValue(let object, let key):
//                guard let string = newValue as? String else { return object.setValue(nil, forKey: key) }
//                object.setValue(string, forKey: key)
//                
//            case .DateValue(let object, let key):
//                guard let date = newValue as? NSDate else { return object.setValue(nil, forKey: key) }
//                object.setValue(date, forKey: key)
//                
//            case .DataValue(let object, let key):
//                guard let data = newValue as? NSData else { return object.setValue(nil, forKey: key) }
//                object.setValue(data, forKey: key)
//                
//                
//            case .ToOneRelationshipValue(let object, let key):
//                guard let relationshipObject = newValue as? RootObect else { return object.setValue(nil, forKey: key) }
//                object.setValue(relationshipObject, forKey: key)
//                
//            case .ToManyRelationshipValue(let object, let key):
//                guard let relationshipObjectSet = newValue as? NSMutableSet else { return object.setValue(nil, forKey: key) }
//                object.setValue(relationshipObjectSet, forKey: key)
//                
//            }
//    
//        }
//    }
//    
//    
//    var image: UIImage? {
//        get {
//            switch self {
//            case .DataValue(let object, let key):
//                guard let imageData = object.valueForKey(key) as? NSData else { return nil }
//                return UIImage(data: imageData)
//            default: return nil
//            }
//        }
//        
//        set {
//            switch self {
//            case .DataValue(let object, let key):
//                guard let image = newValue  else { return object.setValue(nil, forKey: key) }
//                let imageData = UIImageJPEGRepresentation(image, 1.0)
//                object.setValue(imageData, forKey: key)
//            default: return object.setValue(nil, forKey: key)
//            }
//
//        }
//    }
//    
//    var object: RootObect {
//        get {
//            switch self {
//                
//            case .IntValue(let object,_):
//                return object
//            case .FloatValue(let object,_):
//                return object
//            case .DoubleValue(let object,_):
//                return object
//            case .BoolValue(let object,_):
//                return object
//            case .StingValue(let object,_):
//                return object
//            case .DateValue(let object,_):
//                return object
//            case .DataValue(let object,_):
//                return object
//            case .ToOneRelationshipValue(let object,_):
//                return object
//            case .ToManyRelationshipValue(let object,_):
//                return object
//                
//                
//            }
//        }
//    }
//    
//    var key: String {
//        get {
//
//            switch self {
//                
//            case .IntValue(_, let key):
//                return key
//            case .FloatValue(_, let key):
//                return key
//            case .DoubleValue(_, let key):
//                return key
//            case .BoolValue(_, let key):
//                return key
//            case .StingValue(_, let key):
//                return key
//            case .DateValue(_, let key):
//                return key
//            case .DataValue(_, let key):
//                return key
//            case .ToOneRelationshipValue(_, let key):
//                return key
//            case .ToManyRelationshipValue(_, let key):
//                return key
//                
//            }
//        }
//        
//    }
//    
//    var description: String {
//        return "Key: \(key) \n Value: \(value) \n Object: \(object) \n"
//    }
//    
//}












