//
//  DateTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/29/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class DateTableViewCell: UITableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = ""
        detailTextLabel?.text = ""
    }
}