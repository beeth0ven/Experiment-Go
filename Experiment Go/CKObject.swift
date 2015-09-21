//
//  CKObject.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKObject: NSObject {
    
    var record: CKRecord
    
    init(record: CKRecord) { self.record = record }
    
    var recordType: RecordType                  { return RecordType(rawValue: record.recordType)! }
    var recordID: CKRecordID                    { return record.recordID }
    var creationDate: NSDate?                   { return record.creationDate }
    var creatorUserRecordID: CKRecordID?        { return record.creatorUserRecordID }
    var modificationDate: NSDate?               { return record.modificationDate }
    var lastModifiedUserRecordID: CKRecordID?   { return record.lastModifiedUserRecordID }
    var recordChangeTag: String?                { return record.recordChangeTag }
    
    var creatorUser: CKUsers?
    
    
    func saveInBackground(didSave didSave: () -> () ,didFail: ((NSError) -> Void)?) {
        AppDelegate.Cloud.Manager.publicCloudDatabase.saveRecord(record) {
            (_, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error { didFail?(error) ; return }
                didSave()
            }
        }
    }

}

struct RecordKey {
    static let RecordID = "recordID"
    static let CreationDate = "creationDate"
    static let CreatorUserRecordID = "creatorUserRecordID"
    static let ModificationDate = "modificationDate"
    static let LastModifiedUserRecordID = "lastModifiedUserRecordID"
    static let RecordChangeTag = "recordChangeTag"
    static let AboutMe = "aboutMe"
}


enum RecordType: String {
    case Experiment
    case Review
    case Link
    case Users
    case DisplayName
}
