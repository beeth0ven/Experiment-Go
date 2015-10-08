//
//  AuthorTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class UserTableViewCell: CKItemTableViewCell {
    
    var user: CKUsers? {
        get { return item is CKUsers ? item as? CKUsers : item?.creatorUser }
        set { item = newValue }
    }
    
    var profileImage: UIImage {
        get { return profileImageView.image ?? UIImage() }
        set { profileImageView.image = newValue }
    }
    
    var profileImageURL: NSURL? { return user?.profileImageAsset?.fileURL }
    
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.borderColor = UIColor.globalTintColor().CGColor
            profileImageView.layer.borderWidth = profileImageView.bounds.size.height / 32
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    
    
    override func updateUI() {
        profileImage = CKUsers.ProfileImage
        nameLabel.text = user?.displayName
        guard let url = profileImageURL else { return }
        UIImage.GetImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.profileImage = $0 ?? CKUsers.ProfileImage
        }
    }

}