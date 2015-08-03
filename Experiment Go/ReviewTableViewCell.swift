//
//  ReviewTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/2/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ReviewTableViewCell: RootObjectTableViewCell {
    
    
    var review: Review? {
        get {
            return detailItem as? Review
        }
        
        set {
            detailItem = newValue
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
    
    @IBOutlet weak var authorProfileImageView: UIImageView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    
    override func updateUI() {
        authorProfileImage = UIImage.defultTestImage()
        bodyLabel.text = ""
        createDateLabel.text = ""
        guard review != nil else { return }
        authorProfileImage = review!.whoReview!.profileImage
        bodyLabel.text = review!.body
        createDateLabel.text = NSDateFormatter.smartStringFormDate(review!.createDate!)
    }
    
    
}