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
    

    @IBOutlet weak var authorProfileImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var bodyabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    
    override func updateUI() {
        
        authorProfileImage = nil
        
        let review = record!
        let reviewBy = review.createdBy!
        
        bodyabel.text = review[ReviewKey.Body] as? String
        authorLabel.text = reviewBy[UsersKey.DisplayName] as? String
        creationDateLabel.text = review.smartStringForCreationDate
        
        guard let url = profileImageURL else { return }
        
        UIImage.fetchImageForURL(url) { (image) in
            guard url == self.profileImageURL else { return }
            self.authorProfileImage = image
        }
        
    }
    

    
    var authorProfileImage: UIImage? {
        get {
            return authorProfileImageView.image
        }
        set {
            authorProfileImageView.image = newValue
        }
    }
    
    var profileImageURL: NSURL? {
        return (record?.createdBy?[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
    
}
