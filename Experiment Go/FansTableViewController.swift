//
//  FansTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class FansTableViewController: CloudKitTableViewController {
    
    var experiment: CKExperiment?
    
    override var refreshOperation: GetCKItemsOperation {
        return GetExperimentFansOperation(experiment: experiment!)
    }
    
    override var loadNextPageOperation: GetCKItemsOperation? {
        guard let cursor = lastCursor else { return nil }
        return GetExperimentFansOperation(type: .GetNextPage(cursor))
    }
    
    
}