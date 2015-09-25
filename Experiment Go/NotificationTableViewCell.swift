//
//  NotificationTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/9/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit


class NotificationTableViewCell : CKItemTableViewCell {
    
    @IBOutlet weak var aboutMeLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    
    override func updateUI() {
//        aboutMeLabel.text = record?[RecordKey.AboutMe] as? String
//        creationDateLabel.text = record?.smartStringForCreationDate
    }
    
}