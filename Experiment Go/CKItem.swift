//
//  CKItem.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKItem: NSObject {
    
    var record: CKRecord
    
    init(record: CKRecord) { self.record = record }
    
    var recordType: RecordType                  { return RecordType(rawValue: record.recordType)! }
    var recordID: CKRecordID                    { return record.recordID }
    var creationDate: NSDate                    { return record.creationDate ?? NSDate() }
    var creatorUserRecordID: CKRecordID?        { return record.creatorUserRecordID }
    var modificationDate: NSDate?               { return record.modificationDate }
    var lastModifiedUserRecordID: CKRecordID?   { return record.lastModifiedUserRecordID }
    var recordChangeTag: String?                { return record.recordChangeTag }
    var changedKeys: [String]                   { return record.changedKeys() }

    var creatorUser: CKUsers?
    
    var createdByMe: Bool {
        let byMe = creatorUserRecordID!.recordName == CKOwnerDefaultName || creatorUserRecordID!.recordName == CKUsers.CurrentUser?.recordID.recordName
        if byMe && creatorUser == nil && CKUsers.CurrentUser != nil { creatorUser = CKUsers.CurrentUser! }
        return byMe
    }
    
    var hasChange: Bool { return changedKeys.count > 0 }
    
    subscript(key: String) -> CKRecordValue? {
        get { return record[key] }
        set { record[key] = newValue }
    }
    
    static func parseRecord(record: CKRecord) -> CKItem {
        let recordType = RecordType(rawValue: record.recordType)!
        switch recordType {
        case .Users:
            return CKUsers(record: record)
        case .Experiment:
            return CKExperiment(record: record)
        case .Link:
            return CKLink(record: record)
        }
    }
    
    var displayTitle: String? { return nil }

    convenience init(data: NSData) {
        self.init(record: NSKeyedUnarchiver.unarchiveObjectWithData(data) as! CKRecord)
    }
  
    func archivedData() -> NSData
    {
        return NSKeyedArchiver.archivedDataWithRootObject(record)
    }
    
    func saveInBackground(didSave didSave: (Void -> Void)? = nil ,didFail: ((NSError) -> Void)? = nil) {
        CKContainer.defaultContainer().publicCloudDatabase.saveRecord(record) {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { didFail?(error) ; return }
                didSave?()
            }
        }
    }
    
    func deleteInBackground(didDelete didDelete: (Void -> Void)? = nil ,didFail: ((NSError) -> Void)? = nil) {
        CKContainer.defaultContainer().publicCloudDatabase.deleteRecordWithID(recordID) {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { didFail?(error) ; return }
                didDelete?()
            }
        }
    }

}

enum RecordKey: String {
    case recordID
    case creationDate
    case creatorUserRecordID
    case modificationDate
    case lastModifiedUserRecordID
    case recordChangeTag
}


enum RecordType: String {
    case Experiment
    case Link
    case Users
}
