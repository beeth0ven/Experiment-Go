//
//  PublicExtension.swift
//  Experiment Go
//
//  Created by luojie on 7/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData


public func ==(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedSame }
public func <(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedAscending }

extension NSDate: Comparable {}



extension String: CustomStringConvertible {
    public var description: String {
        return self
    }
}

extension UIViewController {
    func hideBarSeparator() {
        let image = UIImage(named: "TransparentPixel")!
        navigationController?.navigationBar.shadowImage = image
        navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        navigationController?.toolbar.setShadowImage(image, forToolbarPosition: .Any)
        navigationController?.toolbar.setBackgroundImage(image, forToolbarPosition: .Any, barMetrics: .Default)
    }
}

extension NSDateFormatter {
    class func smartStringFormDate(date: NSDate) -> String {
        let absTimeIntervalSinceNow = -date.timeIntervalSinceNow
        let OneMinute: Double = 60
        let OneHour: Double = 60 * 60
        let OneDay: Double = 24 * 60 * 60
        if absTimeIntervalSinceNow < OneMinute {
            return "Now"
        } else if absTimeIntervalSinceNow < OneHour {
            // eg. 10 Minutes
            let minutes = Int(absTimeIntervalSinceNow / OneMinute)
            return "\(minutes) m"
        } else if absTimeIntervalSinceNow < OneDay {
            // eg. 10 Hours
            let hours = Int(absTimeIntervalSinceNow / OneHour)
            return "\(hours) h"
        } else {
            // eg. 10 Days
            let days = Int(absTimeIntervalSinceNow / OneDay)
            return "\(days) d"

        }
    }
}

extension UITableViewCell {
    class func setSelectedBackgroundColor(color: UIColor) {
        let view = UIView()
        view.backgroundColor = color
        UITableViewCell.appearance().selectedBackgroundView = view
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if hex.hasPrefix("#") {
            let index   = advance(hex.startIndex, 1)
            let hex     = hex.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                    return nil
                }
            } else {
                print("Scan hex error")
                return nil
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
            return nil
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}