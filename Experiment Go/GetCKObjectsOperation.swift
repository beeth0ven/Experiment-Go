//
//  GetCKItemsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

import CloudKit

class GetCKItemsOperation: NSOperation {
    
    var didGet: (([CKItem], CKQueryCursor?) -> Void)?
    var didFail: HandleFailed?
    
    var currentPageItems  = [CKItem]()
    var currentPageCallBackItems: [CKItem] { return currentPageItems }
    
    
    var type: Type
    
    init(type: Type) {  self.type = type }
    
    func fetchErrorFrom(error: NSError?) -> NSError? {
        guard let error = error else { return nil }
        guard let errorCode = CKErrorCode(rawValue: error.code) else { return error }
        if case .PartialFailure = errorCode { return nil }
        return error
    }
    
    
    enum Type {
        case Refresh(CKQuery)
        case GetNextPage(CKQueryCursor)
        
        var queryOperationToAttempt: CKQueryOperation {
            switch self {
            case .Refresh(let query):
                return CKQueryOperation(query: query)
            case .GetNextPage(let cursor):
                return CKQueryOperation(cursor: cursor)
            }
        }
    }
    
}

extension CKDatabaseOperation {
    func begin() {
        CKContainer.defaultContainer().publicCloudDatabase.addOperation(self)
    }
}