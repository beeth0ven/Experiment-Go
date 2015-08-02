//
//  MenuItemTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/2/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit


class MenuItemTableViewCell: ObjectValueTableViewCell {

    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        contentView.backgroundColor = selected ? UIColor.whiteColor() : DefaultStyleController.Color.Sand
    }

}