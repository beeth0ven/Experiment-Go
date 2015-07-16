//
//  TextFieldTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            textField.becomeFirstResponder()
        }
    }

}
