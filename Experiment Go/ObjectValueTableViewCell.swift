//
//  ObjectValueTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit


class ObjectValueTableViewCell: UITableViewCell {
    
    var objectValue: ObjectValue? { didSet { updateUI() } }
    
    func updateUI() { }
        
}