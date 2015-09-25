//
//  RecordTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/26/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit


class CKItemTableViewCell: UITableViewCell {
    
    var item: CKItem? { didSet { updateUI() } }
    
    func updateUI() {}
    
}