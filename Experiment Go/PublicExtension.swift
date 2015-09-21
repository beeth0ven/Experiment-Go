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

typealias HandleFailed = NSError -> Void

extension UIViewController {
    func handleFail(error: NSError) {
        var message: String
        if let errorCode = CKErrorCode(rawValue: error.code)  {
            switch errorCode{
            case .NetworkUnavailable:
                message = "NetworkUnavailable"
            case .NetworkFailure:
                message = "NetworkFailure"
            case .ServiceUnavailable:
                message = "ServiceUnavailable"
            case .RequestRateLimited:
                message = "RequestRateLimited"
            case .UnknownItem:
                message = "UnknownItem"
            case .InvalidArguments:
                message = "InvalidArguments"
            case .IncompatibleVersion:
                message = "IncompatibleVersion"
            case .BadContainer:
                message = "BadContainer"
            case .MissingEntitlement:
                message = "MissingEntitlement"
            case .PermissionFailure:
                message = "PermissionFailure"
            case .BadDatabase:
                message = "BadDatabase"
            case .AssetFileNotFound:
                message = "AssetFileNotFound"
            case .PartialFailure:
                message = "PartialFailure"
            case .QuotaExceeded:
                message = "QuotaExceeded"
            case .OperationCancelled:
                message = "OperationCancelled"
            case .NotAuthenticated:
                message = "NotAuthenticated"
            case .ResultsTruncated:
                message = "ResultsTruncated"
            case .ServerRecordChanged:
                message = "ServerRecordChanged"
            case .AssetFileModified:
                message = "AssetFileModified"
            case .ChangeTokenExpired:
                message = "ChangeTokenExpired"
            case .BatchRequestFailed:
                message = "BatchRequestFailed"
            case .ZoneBusy:
                message = "ZoneBusy"
            case .ZoneNotFound:
                message = "ZoneNotFound"
            case .LimitExceeded:
                message = "LimitExceeded"
            case .UserDeletedZone:
                message = "UserDeletedZone"
            case .InternalError:
                message = "InternalError"
            case .ServerRejectedRequest:
                message = "ServerRejectedRequest"
            case .ConstraintViolation:
                message = "ConstraintViolation"
            }
        } else {
            message =  error.localizedDescription
        }
        
        let alert = UIAlertController(errorMessage: error.localizedDescription)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension UIAlertController {
    
    convenience init(errorMessage: String) {
        self.init(
            title: "Experiment Go",
            message: errorMessage,
            preferredStyle: .Alert
        )
        self.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
    }
}

extension UIActivityIndicatorView {
    class func defaultView() -> UIActivityIndicatorView {
        let result = self.init(activityIndicatorStyle: .Gray)
        result.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        result.color = UIColor.globalTintColor()
        result.startAnimating()
        result.hidesWhenStopped = true
        return result
    }
}

extension CGRect {
    static let BarButtonItemDefaultRect = CGRectMake(0, 0, 44, 44)

}

extension UIImage {
    class func getImageForURL(url: NSURL, didGet:((UIImage?)->())) {
        if let imageData = AppDelegate.Cache.Manager.assetDataForURL(url) {
            didGet(UIImage(data: imageData))
        } else {
            let qos = QOS_CLASS_USER_INITIATED
            dispatch_async(dispatch_get_global_queue(qos, 0)) {
                var image: UIImage?
                let imageData = NSData(contentsOfURL: url)
                if imageData != nil {
                    AppDelegate.Cache.Manager.cacheAssetData(imageData!, forURL: url)
                    image = UIImage(data: imageData!)
                } else {
                    AppDelegate.Cloud.Manager.getCurrentUserProfileImageIfNeeded()
                }
                dispatch_async(dispatch_get_main_queue()) {
                    didGet(image)
                }
            }
        }
        
        
    }
}

extension CKAsset {
    convenience init(data: NSData) {
        // write the image out to a cache file
        let cachesDirectory = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let temporaryName = NSUUID().UUIDString
        let localURL = cachesDirectory.URLByAppendingPathComponent(temporaryName)
        data.writeToURL(localURL, atomically: true)
        self.init(fileURL: localURL)
    }
}

extension String: CustomStringConvertible {
    public var description: String {
        return self
    }
}

extension UIViewController {
    func setBarSeparatorHidden(hidden: Bool) {
//        print("navigationController title: \(navigationController?.title)")
        let image: UIImage? = hidden ? UIImage.onePixelImageFromColor(UIColor.clearColor()) : nil
        navigationController?.navigationBar.shadowImage = image
        navigationController?.navigationBar.setBackgroundImage(image, forBarMetrics: .Default)
        navigationController?.toolbar.setShadowImage(image, forToolbarPosition: .Any)
        navigationController?.toolbar.setBackgroundImage(image, forToolbarPosition: .Any, barMetrics: .Default)
        navigationController?.hidesBarsOnSwipe = hidden
        if hidden == false { navigationController?.setNavigationBarHidden(false, animated: true) }
    }
    
    func showOrHideToolBarIfNeeded() {
        // Show or hide depends on if toolbarItems is empty
        let show = toolbarItems?.count > 0
        navigationController?.setToolbarHidden(!show, animated: true)
    }
    
    var contentViewController: UIViewController {
        if let nav = self as? UINavigationController {
            return nav.topViewController!
        } else {
            return self
        }
    }
    
    var flexibleSpaceBarButtonItem: UIBarButtonItem  {
        return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    }
    
    var activityBarButtonItem: UIBarButtonItem  {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicatorView.color = navigationController?.navigationBar.tintColor
        activityIndicatorView.startAnimating()
        let result = UIBarButtonItem(customView: activityIndicatorView)
        result.customView!.frame = CGRect.BarButtonItemDefaultRect
        return result
    }
    
    
    var closeBarButtonItem: UIBarButtonItem? {
        guard presentingViewController != nil else { return nil }
        let reselt = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "close")
        return reselt
    }
    
    func close() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showCloseBarButtonItemIfNeeded() {
//        print("navigationController count: \(navigationController?.viewControllers.count)")
        navigationItem.leftItemsSupplementBackButton  = true
        guard closeBarButtonItem != nil else { return }
        guard navigationController?.viewControllers.first == self ||
        navigationController?.viewControllers.count > 4 else { return }
        navigationItem.leftBarButtonItems = [closeBarButtonItem!]
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
            let index   = hex.startIndex.advancedBy(1)
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













