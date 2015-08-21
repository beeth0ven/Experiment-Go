//
//  AuthorTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class AuthorTableViewCell: UITableViewCell {
    
    var profileImage: UIImage? {
        get {
            return profileImageView.image
        }
        set {
            profileImageView.image = newValue
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImage = nil
        nameLabel.text = ""

    }
}