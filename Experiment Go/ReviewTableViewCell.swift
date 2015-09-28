//
//  ReviewTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/2/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ReviewTableViewCell: CKItemTableViewCell {
    
    var review: CKLink? {
        get { return item as? CKLink }
        set { item = newValue }
    }

    @IBOutlet weak var authorProfileImageButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var bodyabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    
    override func updateUI() {
        
        authorProfileImage = nil

        bodyabel.text = review?.content
        authorLabel.text = review?.creatorUser?.displayName
        creationDateLabel.text = review?.creationDate.smartString
        
        guard let url = profileImageURL else { return }
        
        UIImage.getImageForURL(url) {
            guard url == self.profileImageURL else { return }
            self.authorProfileImage = $0
        }
        
    }
    

    
    var authorProfileImage: UIImage? {
        get { return authorProfileImageButton.backgroundImageForState(.Normal) }
        set { authorProfileImageButton.setBackgroundImage(newValue, forState: .Normal) }
    }
    
    var profileImageURL: NSURL? {
        return review?.creatorUser?.profileImageAsset?.fileURL
    }
    
}
