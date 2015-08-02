//
//  DefaultStyleController.swift
//  Experiment Go
//
//  Created by luojie on 8/2/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

class DefaultStyleController {
    
    
    struct Color {
        static let GroupTableViewBackGround = UIColor(hex: "#FFFFFA")!
        static let DarkSand = UIColor(hex: "#CAB77D")!
        static let Sand = UIColor(hex: "#EBD89F")!
    }
    

    class func applyStyle() {
        let backgroundColor = UIColor.flatSandColor().colorWithAlphaComponent(0.25)
        UITableViewCell.setSelectedBackgroundColor(backgroundColor)
    }
}