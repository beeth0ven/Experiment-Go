//
//  AuthorTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class AuthorTableViewCell: RootObjectTableViewCell {
    
    var user: User? {
        get {
            return detailItem as? User
        }
        
        set {
            detailItem = newValue
        }
    }
    
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
    
    override func updateUI() {
        profileImage = UIImage.defultTestImage()
        nameLabel.text = ""
        guard user != nil else { return }
        nameLabel.text = user!.name
        guard let image = user!.profileImage else { return }
        profileImage = image
    }

}