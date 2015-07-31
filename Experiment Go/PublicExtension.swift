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