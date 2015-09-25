//
//  CKExperiment.swift
//  Experiment Go
//
//  Created by luojie on 9/21/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit

class CKExperiment: CKItem {
    
    convenience init() {
        let record = CKRecord(recordType: RecordType.Experiment.rawValue)
        self.init(record: record)
        self.creatorUser = CKUsers.currentUser
        title = "Haha WU han."
        tags = ["ds", "game"]
        purpose = "go anyway"
        content = "Oh my god."
    }
    
    var title: String? {
        get { return record[ExperimentKey.title.rawValue] as? String }
        set { record[ExperimentKey.title.rawValue] = newValue }
    }
    
    var tags: [String]? {
        get { return record[ExperimentKey.tags.rawValue] as? [String] }
        set { record[ExperimentKey.tags.rawValue] = newValue }
    }
    
    var purpose: String? {
        get { return record[ExperimentKey.purpose.rawValue] as? String }
        set { record[ExperimentKey.purpose.rawValue] = newValue }
    }
    
    var principle: String? {
        get { return record[ExperimentKey.principle.rawValue] as? String }
        set { record[ExperimentKey.principle.rawValue] = newValue }
    }

    var content: String? {
        get { return record[ExperimentKey.content.rawValue] as? String }
        set { record[ExperimentKey.content.rawValue] = newValue }
    }
    
    var steps: String? {
        get { return record[ExperimentKey.steps.rawValue] as? String }
        set { record[ExperimentKey.steps.rawValue] = newValue }
    }

    var results: String? {
        get { return record[ExperimentKey.results.rawValue] as? String }
        set { record[ExperimentKey.results.rawValue] = newValue }
    }
    
    var conclusion: String? {
        get { return record[ExperimentKey.conclusion.rawValue] as? String }
        set { record[ExperimentKey.conclusion.rawValue] = newValue }
    }
    
    var footNote: String? {
        get { return record[ExperimentKey.footNote.rawValue] as? String }
        set { record[ExperimentKey.footNote.rawValue] = newValue }
    }
    
    override var displayTitle: String? { return title }
//    
//    override subscript(key: String) -> AnyObject? {
//        get {
//            guard let experimentKey = ExperimentKey(rawValue: key) else { return super[key] }
//
//            switch experimentKey {
//            case .title:
//                return title
//            case .tags:
//                return tags
//            case .purpose:
//                return purpose
//            case .principle:
//                return principle
//            case .content:
//                return content
//            case .steps:
//                return steps
//            case .results:
//                return results
//            case .conclusion:
//                return conclusion
//            case .footNote:
//                return footNote
//            }
//        }
//        
//        set {
//            guard let experimentKey = ExperimentKey(rawValue: key) else { return }
//            switch experimentKey {
//            case .title:
//                title = newValue as? String
//            case .tags:
//                tags = newValue as? [String]
//            case .purpose:
//                purpose = newValue as? String
//            case .principle:
//                principle = newValue as? String
//            case .content:
//                content = newValue as? String
//            case .steps:
//                steps = newValue as? String
//            case .results:
//                results = newValue as? String
//            case .conclusion:
//                conclusion = newValue as? String
//            case .footNote:
//                footNote = newValue as? String
//            }
//        }
    

//    }

}


enum ExperimentKey: String {
    case title
    case tags
    case purpose
    case principle
    case content
    case steps
    case results
    case conclusion
    case footNote
}
