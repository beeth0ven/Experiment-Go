//
//  FollowLinkTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class FollowLinkTableViewCell: LinkTableViewCell {
    
    override func updateUI() {
        
        fromUserNameLabel.text = link?.creatorUser?.displayName
        subheadLabel.text = "is following you."
        dateLabel.text = link?.creationDate.smartString
        
        fromUserProfileImage = nil
        guard let url = fromUserProfileImageURL else { return }
        UIImage.getImageForURL(url) {
            guard url == self.fromUserProfileImageURL else { return }
            self.fromUserProfileImage = $0
        }
    }
}