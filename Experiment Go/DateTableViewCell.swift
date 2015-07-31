//
//  DateTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/29/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class DateTableViewCell: ObjectValueTableViewCell {
    
    override func updateUI() {
        textLabel?.text = ""
        detailTextLabel?.text = ""
        guard let objectValue = objectValue else { return }
        textLabel?.text = objectValue.key.capitalizedString
        guard let date = objectValue.value as? NSDate else { return }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        detailTextLabel?.text = dateFormatter.stringFromDate(date)
    }
}