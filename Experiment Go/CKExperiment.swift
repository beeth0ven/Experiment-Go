//
//  CKExperiment.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKExperiment: CKObject {
    
    var title: String? {
        get { return record[ExperimentKey.Title] as? String }
        set { record[ExperimentKey.Title] = newValue }
    }
    
    var tags: [String]? {
        get { return record[ExperimentKey.Tags] as? [String] }
        set { record[ExperimentKey.Tags] = newValue }
    }
    
    var purpose: String? {
        get { return record[ExperimentKey.Purpose] as? String }
        set { record[ExperimentKey.Purpose] = newValue }
    }
    
    var principle: String? {
        get { return record[ExperimentKey.Principle] as? String }
        set { record[ExperimentKey.Principle] = newValue }
    }

    var content: String? {
        get { return record[ExperimentKey.Content] as? String }
        set { record[ExperimentKey.Content] = newValue }
    }
    
    var steps: String? {
        get { return record[ExperimentKey.Steps] as? String }
        set { record[ExperimentKey.Steps] = newValue }
    }

    var results: String? {
        get { return record[ExperimentKey.Results] as? String }
        set { record[ExperimentKey.Results] = newValue }
    }
    
    var conclusion: String? {
        get { return record[ExperimentKey.Conclusion] as? String }
        set { record[ExperimentKey.Conclusion] = newValue }
    }
    
    var footNote: String? {
        get { return record[ExperimentKey.FootNote] as? String }
        set { record[ExperimentKey.FootNote] = newValue }
    }
}



struct ExperimentKey {
    static let RecordType = "Experiment"
    static let Title = "title"
    static let Conclusion = "conclusion"
    static let Reviews = "reviews"
    static let Fans = "fans"
    static let Content = "content"
    static let FootNote = "footNote"
    static let Principle = "principle"
    static let Purpose = "purpose"
    static let Results = "results"
    static let Steps = "steps"
    static let Tags = "tags"
    
}