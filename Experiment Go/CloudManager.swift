//
//  CloudManager.swift
//  BabiFood
//
//  Created by luojie on 8/7/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import UIKit

protocol CloudSupport: class {
    
    func saveNewObjectFromRecord(record: CKRecord)
    func saveNewRecordToCloud(completionHandler: (CKRecord?, NSError?) -> Void)
    func readRecordFormCloud(completionHandler: (CKRecord?, NSError?) -> Void)
    func updateRecordToCloud(completionHandler: (CKRecord?, NSError?) -> Void)
    func updateRecordFromCloud(completionHandler: (CKRecord?, NSError?) -> Void)
    func deleteRecordFormCloud(completionHandler: (CKRecordID?, NSError?) -> Void)

    func configToRecord(record: CKRecord)
    func configFromRecord(record: CKRecord)

}

protocol CKRecordConvertible: class {
    var recordID: String? { get set }
    var creationDate: NSDate? { get set }
    var creatorUserRecordID: String? { get set }
    var modificationDate: NSDate? { get set }
    var lastModifiedUserRecordID: String? { get set }
    var recordChangeTag: String? { get set }
}


class CloudManager {

    struct Constants {
        static let RecordIDKey = "recordID"
        static let CreationDateKey = "creationDate"
        static let AuthorIDKey = "creatorUserRecordID"
        static let ModificationDateKey = "modificationDate"
        static let LastModifiedUserIDKey = "lastModifiedUserRecordID"
        static let RecordChangeTagKey = "recordChangeTag"

        static let FetchedBy = 1
    }
    
    var fetchRequest: NSFetchRequest
    var queryCursor: CKQueryCursor?
    var isLoadingBatch = false
    
    
    required init(fetchRequest: NSFetchRequest) {
        self.fetchRequest = fetchRequest
    }
    
    func fetchNextPageByDate(date: NSDate, completionHandler: ((NSError?) -> Void)?) {
        let cloudQuery = CKQuery(fetchRequest: fetchRequest, beforeDate: date)
        performByQuery(cloudQuery, completionHandler: completionHandler)
    }
    
    func fetchPreviousPageByDate(date: NSDate, completionHandler: ((NSError?) -> Void)?) {
        let cloudQuery = CKQuery(fetchRequest: fetchRequest, afterDate: date)
        performByQuery(cloudQuery, completionHandler: completionHandler)
    }
    
    func performByQuery(query: CKQuery, completionHandler: ((NSError?) -> Void)?) {
        guard isLoadingBatch == false else { return print("A querry is in process.") }
        isLoadingBatch = true
        
        let queryOp = CKQueryOperation(query: query)
        queryOp.resultsLimit = Constants.FetchedBy
        queryOp.recordFetchedBlock = {
            (record) in
            self.parseRecord(record)
        }
        
        queryOp.queryCompletionBlock = {
            (queryCursor, error) in
            if error == nil {
                self.queryCursor = queryCursor
                NSManagedObjectContext.saveContextFromCloud()
                print("Successfully to fetched records from cloud.")
            } else {
                print("Failed to fetche record from cloud.")
            }
            self.isLoadingBatch = false
            dispatch_async(dispatch_get_main_queue()) { completionHandler?(error) }
        }
        
        NSManagedObjectContext.cloudPublicContext().addOperation(queryOp)
    }
    

    private func parseRecord(record: CKRecord){
        let request = NSFetchRequest(entityName: record.recordType)
        request.predicate = NSPredicate(format: "id = %@", record.recordID.recordName)
        var matches: [AnyObject]
        do {
            matches = try NSManagedObjectContext.defaultContext().executeFetchRequest(request)
        } catch {
            abort()
        }
        
        if matches.count == 0 {
            let object = NSEntityDescription.insertNewObjectForEntityForName(record.recordType, inManagedObjectContext: NSManagedObjectContext.defaultContext())
            guard let objectSupportCloud = object as? CloudSupport else { return print("Failed to parse record, \(record.recordType) isn't Support Cloud. ") }
            objectSupportCloud.saveNewObjectFromRecord(record)
        } else if matches.count == 1 {
            // Maybe Update local object.
            guard let objectSupportCloud = matches.first! as? CloudSupport else { return print("Failed to parse record, \(record.recordType) isn't Support Cloud. ") }
            objectSupportCloud.configFromRecord(record)
        } else {
            // Error case same objects exist.
            print("Error case same objects exist.")
        }

    }
    

}

extension NSManagedObjectContext {

    class func cloudPublicContext() -> CKDatabase {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appdelegate.cloudContext
    }
    
    
    class func saveContextFromCloud() {
        let managedObjectContext = defaultContext()
        managedObjectContext.performBlock {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
       
    }
    
    class func saveContextToCloud(completionHandler:((NSError?) -> Void)?) {
        
        let managedObjectContext = defaultContext()
        let saveLocalContextOp: () -> Void = {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
        
        guard managedObjectContext.hasChanges else { return }
        // 1 Save New Record
        let insertedObjects = managedObjectContext.insertedObjects
        for object in insertedObjects {
            guard let objectSupportCloud = object as? CloudSupport else { continue }
            objectSupportCloud.saveNewRecordToCloud{ (record, error) -> Void in
                if error == nil {
                    saveLocalContextOp()
                    print("Successfully to save \(record!.recordType) to cloud.")
                } else {
                    print("Failed to create record to cloud.")
                }
                dispatch_async(dispatch_get_main_queue()) { completionHandler?(error) }
            }
            
        }
        
        // 2 Read and Write Record
        let updatedObjects = managedObjectContext.updatedObjects
        for object in updatedObjects {
            guard let objectSupportCloud = object as? CloudSupport else { continue }
            objectSupportCloud.updateRecordToCloud{ (record, error) -> Void in
                if error == nil {
                    saveLocalContextOp()
                    print("Successfully to update \(record!.recordType) to cloud.")
                } else {
                    print("Failed to update record to cloud.")
                }
                
                dispatch_async(dispatch_get_main_queue()) { completionHandler?(error) }
            }
            
        }
        
        // 3 Delete Record
        let deletedObjects = managedObjectContext.deletedObjects
        for object in deletedObjects {
            guard let objectSupportCloud = object as? CloudSupport else { continue }
            objectSupportCloud.deleteRecordFormCloud{ (recordID, error) -> Void in
                if error == nil {
                    saveLocalContextOp()
                    print("Successfully to delete record with id \(recordID!.recordName) from cloud.")
                } else {
                    print("Failed to delete record from cloud.")
                }
                dispatch_async(dispatch_get_main_queue()) { completionHandler?(error) }
            }
        }
        
        
        
        
        
    }
}

extension NSFetchedResultsController {
   
}

extension CKQuery {
    
    convenience init(fetchRequest: NSFetchRequest, beforeDate: NSDate) {
        let datePredicate = NSPredicate(format: "timeStamp < %@", beforeDate)
        let predicates = [fetchRequest.predicate ?? NSPredicate(value: true) , datePredicate]
        let cloudPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: predicates)
        self.init(recordType: fetchRequest.entity!.name!, predicate: cloudPredicate)
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: false)
        self.sortDescriptors = [sortDescriptor]
    }
    
    convenience init(fetchRequest: NSFetchRequest, afterDate: NSDate) {
        let datePredicate = NSPredicate(format: "timeStamp > %@", afterDate)
        let predicates = [fetchRequest.predicate ?? NSPredicate(value: true) , datePredicate]
        let cloudPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: predicates)
        self.init(recordType: fetchRequest.entity!.name!, predicate: cloudPredicate)
        let sortDescriptor = NSSortDescriptor(key: "timeStamp", ascending: true)
        self.sortDescriptors = [sortDescriptor]
    }
}

