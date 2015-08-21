//
//  PublicExtension.swift
//  Experiment Go
//
//  Created by luojie on 7/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


public func ==(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedSame }
public func <(date0: NSDate, date1: NSDate) -> Bool { return date0.compare(date1) == NSComparisonResult.OrderedAscending }

extension NSDate: Comparable {}

extension CKAsset {
    convenience init(data: NSData) {
        // write the image out to a cache file
        let cachesDirectory = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let temporaryName = NSUUID().UUIDString
        let localURL = cachesDirectory.URLByAppendingPathComponent(temporaryName)
        data.writeToURL(localURL, atomically: true)
        self.init(fileURL: localURL)
    }
    
    var data: NSData? {
        var result = defaultCache.objectForKey(fileURL.pathExtension!) as? NSData
        guard result == nil else { return result! }
        result = NSData(contentsOfURL: fileURL)
        if result != nil { defaultCache.setObject(result!, forKey: fileURL.pathExtension!)  }
        return result
    }
    
    
}

extension String: CustomStringConvertible {
    public var description: String {
        return self
    }
}

extension UIViewController {
    func hideBarSeparator() {
        let image = UIImage.onePixelImageFromColor(UIColor.clearColor())
        navigationController?.navigationBar.shadowImage = image
        navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        navigationController?.toolbar.setShadowImage(image, forToolbarPosition: .Any)
        navigationController?.toolbar.setBackgroundImage(image, forToolbarPosition: .Any, barMetrics: .Default)
    }
    
    var contentViewController: UIViewController {
        if let nav = self as? UINavigationController {
            return nav.topViewController!
        } else {
            return self
        }
    }
}

extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem()
        UIApplication.sharedApplication().sendAction(barButtonItem.action,
            to: barButtonItem.target,
            from: barButtonItem,
            forEvent: nil
        )
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
            return "\(minutes) minutes ago"
        } else if absTimeIntervalSinceNow < OneDay {
            // eg. 10 Hours
            let hours = Int(absTimeIntervalSinceNow / OneHour)
            return "\(hours) hours ago"
        } else {
            // eg. 10 Days
            let days = Int(absTimeIntervalSinceNow / OneDay)
            return "\(days) days ago"

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
    
    class func globalTintColor() -> UIColor {
        return UIApplication.sharedApplication().keyWindow!.tintColor
    }
}

extension UIImage {
    class func onePixelImageFromColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContext(CGSizeMake(1, 1))
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillEllipseInRect(context, CGRectMake(0, 0, 1, 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func resizableImageFromColor(color: UIColor, cornerRadius: CGFloat) -> UIImage {
        let size = CGSizeMake(2 * cornerRadius, 2 * cornerRadius)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillEllipseInRect(context, CGRectMake(0, 0, size.width, size.height))
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        image = image.resizableImageWithCapInsets(UIEdgeInsets(top: cornerRadius, left: cornerRadius, bottom: cornerRadius, right: cornerRadius))
        return image
    }
}













