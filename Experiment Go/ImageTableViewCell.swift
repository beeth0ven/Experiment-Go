//
//  ImageTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    
    var profileImageURL: NSURL? { didSet { updateUI() } }
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.borderColor = UIColor.globalTintColor().CGColor
            profileImageView.layer.borderWidth = profileImageView.bounds.size.height / 32
        }
    }
    
    var profileImge: UIImage {
        get { return profileImageView.image ?? UIImage() }
        set { profileImageView.image = newValue }
    }
    
    
    func updateUI() {
        profileImge = CKUsers.ProfileImage
        guard let url = profileImageURL else { return }
        UIImage.GetImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.profileImge = $0 ?? CKUsers.ProfileImage
        }
    }
    

}
