//
//  TableViewDataStructController.swift
//  Experiment Go
//
//  Created by luojie on 7/26/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocol Fetched Info Controller Data Source

protocol FetchedInfoControllerDataSource: class {
    
    func identifiersForSectionInfos() -> [String]
    func sectionInfoForIdentifier(identifier: String) -> SectionInfo
    
    func cellKeysBySectionInfo(sectionInfo: SectionInfo) -> [String]?
}



class FetchedInfoController {

    weak var dataSource: FetchedInfoControllerDataSource? {
        didSet {
            configureDataStruct()
        }
    }
    
    var sections: [SectionInfo] = []
        private func configureDataStruct() {
        guard dataSource != nil else { return }
        var result: [SectionInfo] = []
        for identifer in dataSource!.identifiersForSectionInfos() {
            let sectionInfo = dataSource!.sectionInfoForIdentifier(identifer)
            switch sectionInfo.style {
            case .Attribute:
                sectionInfo.cellKeys = dataSource!.cellKeysBySectionInfo(sectionInfo)
            default: break
            }
            result.append(sectionInfo)
        }
        sections = result
    }
    
}

typealias IsManagedObjectOrderedBefore = (RootObject, RootObject) -> Bool

class SectionInfo {
    var identifier: String
    var style: Style
    var editingStyles: [EditingStyle]
    
    var cellKeys: [String]?
    
    
    required init(identifier: String, style: Style, editingStyles: [EditingStyle]) {
        self.identifier = identifier
        self.style = style
        self.editingStyles = editingStyles
    }
    
    var name: String {
        return identifier
    }
    
    enum Style {
        case Attribute
        case ToOneRelationship(String)
        case ToManyRelationship(String, IsManagedObjectOrderedBefore)
        
    }
    
    enum EditingStyle {
        case Insert
        case Delete
    }
    
}




