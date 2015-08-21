//
//  ExperimentTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ExperimentTableViewCell: UITableViewCell {

    var authorProfileImage: UIImage? {
        get {
            return authorProfileImageView.image
        }
        set {
            authorProfileImageView.image = newValue
        }
    }
    
    @IBOutlet weak var authorProfileImageView: UIImageView! {
        didSet {
//            // Add border
//            authorProfileImageView.layer.borderColor = DefaultStyleController.Color.Sand.CGColor
//            authorProfileImageView.layer.borderWidth = authorProfileImageView.bounds.size.height / 16
//            // Add corner radius
//            authorProfileImageView.layer.cornerRadius = authorProfileImageView.bounds.size.height / 2
//            authorProfileImageView.layer.masksToBounds = true
        }
        
    }
//    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!

}
