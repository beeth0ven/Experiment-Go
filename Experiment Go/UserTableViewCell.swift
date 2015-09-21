//
//  AuthorTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class UserTableViewCell: RecordTableViewCell {
    
    var user: CKUsers? {
        get { return object as? CKUsers }
        set { object = newValue }
    }
    
    var profileImage: UIImage? {
        get {
            return profileImageView.image
        }
        set {
            profileImageView.image = newValue
        }
    }
    
    var profileImageURL: NSURL? {
        return user?.profileImageAsset?.fileURL
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    override func updateUI() {
        profileImage = nil
        nameLabel.text = user?.displayName
        guard let url = profileImageURL else { return }
        UIImage.getImageForURL(url) { (image) in
            guard url == self.profileImageURL else { return }
            self.profileImage = image
        }
    }

}