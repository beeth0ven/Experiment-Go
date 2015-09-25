//
//  ExperimentTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ExperimentTableViewCell: CKItemTableViewCell {
    
    var experiment: CKExperiment? {
        get { return item as? CKExperiment }
        set { item = newValue }
    }

    var authorProfileImage: UIImage? {
        get { return authorProfileImageButton.backgroundImageForState(.Normal) }
        set { authorProfileImageButton.setBackgroundImage(newValue, forState: .Normal) }
    }
    
    var profileImageURL: NSURL? { return experiment?.creatorUser?.profileImageAsset?.fileURL }
    
    @IBOutlet weak var authorProfileImageButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    override func updateUI() {
        authorProfileImage = nil
        
        titleLabel.text = experiment?.title
        authorLabel.text = experiment?.creatorUser?.displayName
        creationDateLabel.text = (experiment?.creationDate ?? NSDate()).smartString
        
        guard let url = profileImageURL else { return }
        
        UIImage.getImageForURL(url) { (image) in
            guard url == self.profileImageURL else { return }
            self.authorProfileImage = image
        }
    }
}
