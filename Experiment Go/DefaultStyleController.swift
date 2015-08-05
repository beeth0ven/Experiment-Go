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
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        let splitViewController = appDelegate?.window?.rootViewController as? UISplitViewController
        
        // Set global tint color.
        let globalTintColor = Color.Sand
        appDelegate?.window?.tintColor = globalTintColor
        
        // Change tableViewCell selected color
        let backgroundColor = globalTintColor.colorWithAlphaComponent(0.25)
        UITableViewCell.setSelectedBackgroundColor(backgroundColor)
        
        // Remove split view gray separator
        splitViewController?.view.backgroundColor = UIColor.whiteColor()

    }
    
}