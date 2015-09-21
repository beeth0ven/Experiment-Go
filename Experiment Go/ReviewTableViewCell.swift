//
//  ReviewTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/2/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ReviewTableViewCell: RecordTableViewCell {
    

    @IBOutlet weak var authorProfileImageButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var bodyabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    
    override func updateUI() {
        
//        authorProfileImage = nil
//        
//        let review = record!
//        let reviewBy = review.createdBy!
//        
//        bodyabel.text = review[ReviewKey.Body] as? String
//        authorLabel.text = reviewBy[UsersKey.DisplayName] as? String
//        creationDateLabel.text = review.smartStringForCreationDate
//        
//        guard let url = profileImageURL else { return }
//        
//        UIImage.getImageForURL(url) {
//            guard url == self.profileImageURL else { return }
//            self.authorProfileImage = $0
//        }
        
    }
    

    
//    var authorProfileImage: UIImage? {
//        get { return authorProfileImageButton.backgroundImageForState(.Normal) }
//        set { authorProfileImageButton.setBackgroundImage(newValue, forState: .Normal) }
//    }
//    
//    var profileImageURL: NSURL? {
//        return (record?.createdBy?[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL
//    }
    
}
