//
//  ReviewLinkTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ReviewLinkTableViewCell: LinkTableViewCell {
    
    @IBOutlet weak var experimentButton: UIButton!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func updateUI() {
        
        fromUserNameLabel.text = link?.creatorUser?.displayName
        subheadLabel.text = NSLocalizedString("reviewed to:", comment: "") 
        experimentButton.setTitle(link?.experiment?.title, forState: .Normal)
        contentLabel.text = link?.content
        dateLabel.text = link?.creationDate.smartString
        
        fromUserProfileImage = CKUsers.ProfileImage
        guard let url = fromUserProfileImageURL else { return }
        UIImage.GetImageForURL(url) {
            guard url == self.fromUserProfileImageURL else { return }
            self.fromUserProfileImage = $0 ?? CKUsers.ProfileImage
        }
    }
    
}