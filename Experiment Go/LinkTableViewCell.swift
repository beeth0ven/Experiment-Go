//
//  LinkTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class LinkTableViewCell: CKItemTableViewCell {
    
    var link: CKLink? {
        get { return item as? CKLink }
        set { item = newValue }
    }
    
    
    @IBOutlet weak var fromUserProfileImageButton: UIButton! {
        didSet {
            fromUserProfileImageButton.layer.borderColor = UIColor.globalTintColor().CGColor
            fromUserProfileImageButton.layer.borderWidth = fromUserProfileImageButton.bounds.size.height / 32
        }
    }
    @IBOutlet weak var fromUserNameLabel: UILabel!
    @IBOutlet weak var subheadLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var fromUserProfileImage: UIImage {
        get { return fromUserProfileImageButton.backgroundImageForState(.Normal) ?? UIImage() }
        set { fromUserProfileImageButton.setBackgroundImage(newValue, forState: .Normal) }
    }
    
    var fromUserProfileImageURL: NSURL? { return link?.creatorUser?.profileImageAsset?.fileURL }
    

}