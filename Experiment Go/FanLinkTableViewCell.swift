//
//  FanLinkTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class FanLinkTableViewCell: LinkTableViewCell {
    
    @IBOutlet weak var experimentButton: UIButton!
    
    override func updateUI() {
        
        fromUserNameLabel.text = link?.creatorUser?.displayName
        subheadLabel.text = NSLocalizedString("liked:", comment: "") 
        experimentButton.setTitle(link?.experiment?.title, forState: .Normal)
        dateLabel.text = link?.creationDate.smartString
        
        fromUserProfileImage = CKUsers.ProfileImage
        guard let url = fromUserProfileImageURL else { return }
        UIImage.GetImageForURL(url) {
            guard url == self.fromUserProfileImageURL else { return }
            self.fromUserProfileImage = $0 ?? CKUsers.ProfileImage
        }
    }
}