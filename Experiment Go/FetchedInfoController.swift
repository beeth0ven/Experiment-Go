//
//  TableViewDataStructController.swift
//  Experiment Go
//
//  Created by luojie on 7/26/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

// FetchedInfoController provide a data structure for the table view controller which has a managed object as model,
// FetchedInfoController plays like fetched result controller.

import Foundation
import CoreData

// MARK: - Protocol Fetched Info Controller Data Source

protocol FetchedInfoControllerDataSource: class {
    // Provide all sections use it's identifier.
    func identifiersForSectionInfos() -> [String]
    // Provide section detail infomation by it's identifier.
    func sectionInfoForIdentifier(identifier: String) -> SectionInfo
    
    // Provide keys for cellls in a section which's type is attribute.
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
    
    func reloadDataStruct() {
        configureDataStruct()
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




