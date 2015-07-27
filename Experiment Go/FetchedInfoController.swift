//
//  TableViewDataStructController.swift
//  Experiment Go
//
//  Created by luojie on 7/26/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// MARK: - Protocol Fetched Info Controller Data Source

protocol FetchedInfoControllerDataSource: class {
    
    func keysForSectionInfos() -> [String]
    func sectionInfoForKey(key: String) -> SectionInfo
    
    func keysForCellInfosBySectionInfo(sectionInfo: SectionInfo) -> [String]
    func cellInfoForKey(key: String, bySectionInfo sectionInfo: SectionInfo) -> CellInfo
}



class FetchedInfoController {
    
    
    struct Constants {
        static let InsertStyleKey = "InsertStyleKey"
    }
    

    
    weak var dataSource: FetchedInfoControllerDataSource? {
        didSet {
            configureDataStruct()
        }
    }
    
    var sections: [SectionInfo] = []
    
    func cellInfoForInsertStyleAtIndexPath(indexPath: NSIndexPath) -> CellInfo? {
        guard indexPath.section < sections.count else { return nil }
        let sectionInfo = sections[indexPath.section]
        
        switch sectionInfo.style {
        case .Attribute:
            return nil
            
        case .ToOneRelationship(_):
            return nil
            
        case .ToManyRelationship(_):
            return sectionInfo.cellInfos.filter { $0.key == Constants.InsertStyleKey }.first
            
        }
    }
    
    func cellInfoAtIndexPath(indexPath: NSIndexPath) -> CellInfo? {
        guard indexPath.section < sections.count else { return nil }
        let sectionInfo = sections[indexPath.section]
        
        switch sectionInfo.style {
        case .Attribute:
            guard indexPath.row < sectionInfo.cellInfos.count else { return nil }
            return sectionInfo.cellInfos[indexPath.row]
            
        case .ToOneRelationship(_):
            return sectionInfo.cellInfos[0]
            
        case .ToManyRelationship(_):
            return sectionInfo.cellInfos[0]
            
        }
    }
    
    private func configureDataStruct() {
        guard dataSource != nil else { return }
        var result: [SectionInfo] = []
        for sectionKey in dataSource!.keysForSectionInfos() {
            let sectionInfo = dataSource!.sectionInfoForKey(sectionKey)
            sectionInfo.cellInfos = cellInfosBySectionInfo(sectionInfo)
            result.append(sectionInfo)
        }
        
        sections = result
        
    }
    
    
    private func cellInfosBySectionInfo(sectionInfo: SectionInfo) -> [CellInfo] {
        var cellInfos: [CellInfo] = []
        guard let dataSource = dataSource else { return cellInfos }
        for cellKey in dataSource.keysForCellInfosBySectionInfo(sectionInfo) {
            let cellInfo = dataSource.cellInfoForKey(cellKey, bySectionInfo: sectionInfo)
            cellInfos.append(cellInfo)
        }
        return cellInfos
    }
    
}

class SectionInfo {
    var key: String
    var style: Style
    var editingStyles: [EditingStyle]

    var cellInfos = [CellInfo]()

    
    required init(key: String, style: Style, editingStyles: [EditingStyle]) {
        self.key = key
        self.style = style
        self.editingStyles = editingStyles
    }
    
    var name: String {
        return key
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

typealias ConfigureCellUseObect = (UITableViewCell, RootObect) -> ()
typealias IsManagedObjectOrderedBefore = (RootObect, RootObect) -> Bool

class CellInfo {
    struct Storyboard {
        static let BasicCellReuseIdentifier = "BasicCell"
        static let InsertCellReuseIdentifier = "BasicCell"
        static let RightDetailCellReuseIdentifier = "RightDetailCell"
        static let TextFieldCellReuseIdentifier = "TextFieldCell"
        
    }
    

    var key: String
    var style: Style
    
    required init(key: String, style: Style) {
        self.key = key
        self.style = style
    }
    
    
    enum Style {
        case Basic(         ConfigureCellUseObect )
        case RightDetail(   ConfigureCellUseObect )
        case TextField(     ConfigureCellUseObect )
        
        var cellReuseIdentifier: String {
            switch self {
            case .Basic(_):
                return Storyboard.BasicCellReuseIdentifier
            case .RightDetail(_):
                return Storyboard.RightDetailCellReuseIdentifier
            case .TextField(_):
                return Storyboard.TextFieldCellReuseIdentifier
            }
        }
        
        var configureCellUseObect: ConfigureCellUseObect {
            switch self {
            case .Basic(let op):
                return op
            case .RightDetail(let op):
                return op
            case .TextField(let op):
                return op
            }
        }
        
    }
    
    
}


