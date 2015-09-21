//
//  GetCKObjectsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

import CloudKit

class GetCKObjectsOperation: NSOperation {
    var didGet: (([CKObject], CKQueryCursor?) -> Void)?
    var didFail: HandleFailed?
    
    var type: Type
    
    init(type: Type) {  self.type = type }
    
    enum Type {
        case Refresh(CKQuery)
        case LoadNextPage(CKQueryCursor)
        
        var queryOperationToAttempt: CKQueryOperation {
            switch self {
            case .Refresh(let query):
                return CKQueryOperation(query: query)
            case .LoadNextPage(let cursor):
                return CKQueryOperation(cursor: cursor)
            }
        }
    }
}