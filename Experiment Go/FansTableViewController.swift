//
//  FansTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import CloudKit

class FansTableViewController: CloudKitTableViewController {
    
    var likedExperiment: CKRecord?
    
    override func queryPredicate() -> NSPredicate {
        guard let likedExperiment = likedExperiment else { return super.queryPredicate() }
        return NSPredicate(format: "%K = %@", FanLinkKey.ToExperiment, likedExperiment)
    }
    
}