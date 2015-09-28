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
    
    // MARK: - CKQuery
    
    var reviewsQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: reviewsQueryPredicate)
    }
    
    private var reviewsQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue, LinkType.UserReviewToExperiment.rawValue)
        let experimentPredicate = NSPredicate(format: "%K = %@", LinkKey.experimentRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [typePredicate, experimentPredicate])
    }
    
    var fansQuery: CKQuery {
        return CKQuery(recordType: .Link, predicate: fansQueryPredicate)
    }
    
    private var fansQueryPredicate: NSPredicate {
        let typePredicate = NSPredicate(format: "%K = %@", LinkKey.linkType.rawValue, LinkType.UserLikeExperiment.rawValue)
        let experimentPredicate = NSPredicate(format: "%K = %@", LinkKey.experimentRef.rawValue, recordID)
        return NSCompoundPredicate(type: .AndPredicateType, subpredicates: [typePredicate, experimentPredicate])
    }
    
    static func QueryForSearchText(text: String?) -> CKQuery {
        return CKQuery(recordType: .Experiment, predicate: PredicateForSearchText(text))
    }
    
    static private func PredicateForSearchText(text: String?) -> NSPredicate {
        let texts: [String] = String.isBlank(text) ? [] : text!.lowercaseString.componentsSeparatedByString(" ")
        guard texts.count > 0 else { return NSPredicate(value: true) }
        let tagsPredicates = texts.map { NSPredicate(format: "%K CONTAINS %@", ExperimentKey.tags.rawValue , $0) }
        let tagsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: tagsPredicates)
//        let titlePredicates = texts.map { NSPredicate(format: "%K CONTAINS %@", ExperimentKey.title.rawValue , $0) }
//        let titlePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: titlePredicates)
        return tagsPredicate
//            NSCompoundPredicate(orPredicateWithSubpredicates: [tagsPredicate, titlePredicate])
    }
}

extension CKQuery {
    
    convenience init(recordType: RecordType, predicate: NSPredicate) {
        self.init(recordType: recordType.rawValue, predicate: predicate)
        self.sortDescriptors = [NSSortDescriptor(key: RecordKey.creationDate.rawValue, ascending: false)]
    }
    
    convenience init(recordType: String) {
        self.init(recordType: RecordType(rawValue: recordType)!.rawValue, predicate: NSPredicate(value: true))
        self.sortDescriptors = [NSSortDescriptor(key: RecordKey.creationDate.rawValue, ascending: false)]
        
    }
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
