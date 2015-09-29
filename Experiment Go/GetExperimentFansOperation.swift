//
//  GetExperimentFansOperation.swift
//  Experiment Go
//
//  Created by luojie on 9/27/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import Foundation
import CloudKit

class GetExperimentFansOperation: GetObjectsWithCreatorUserOperation {
    
    convenience init(to experiment: CKExperiment) {
        self.init(type: .Refresh(experiment.fansQuery))
    }
    
    
}