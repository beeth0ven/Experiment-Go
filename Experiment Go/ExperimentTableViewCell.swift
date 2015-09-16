//
//  ExperimentTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ExperimentTableViewCell: RecordTableViewCell {

    var authorProfileImage: UIImage? {
        get {
            return authorProfileImageButton.backgroundImageForState(.Normal)
        }
        set {
            authorProfileImageButton.setBackgroundImage(newValue, forState: .Normal)
        }
    }
    
    var profileImageURL: NSURL? {
        return (record?.createdBy?[UsersKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
    
    @IBOutlet weak var authorProfileImageButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    override func updateUI() {
        authorProfileImage = nil

        let experiment = record!
        titleLabel.text = experiment[ExperimentKey.Title] as? String
        authorLabel.text = experiment.createdBy?[UsersKey.DisplayName] as? String
        creationDateLabel.text = NSDateFormatter.smartStringFormDate(experiment.creationDate!)
        
        guard let url = profileImageURL else { return }
        
        UIImage.fetchImageForURL(url) { (image) in
            guard url == self.profileImageURL else { return }
            self.authorProfileImage = image
        }
    }
}
