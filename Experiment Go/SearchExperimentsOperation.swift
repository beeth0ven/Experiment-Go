//
//  SearchExperimentsOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class SearchExperimentsOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(searchText: String?) {
        self.init(type: .Refresh(CKExperiment.QueryForSearchText(searchText)))
    }
    
    
}