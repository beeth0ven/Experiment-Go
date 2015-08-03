//
//  ExperimentTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ExperimentTableViewCell: RootObjectTableViewCell {

    
    var experiment: Experiment? {
        get {
            return detailItem as? Experiment
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
//    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    

    override func updateUI() {
        authorProfileImage = UIImage.defultTestImage()
//        authorNameLabel.text = ""
        titleLabel.text = ""
        createDateLabel.text = ""
        guard experiment != nil else { return }
        authorProfileImage = experiment!.whoPost!.profileImage
//        authorNameLabel.text = experiment!.whoPost!.name
        titleLabel.text = experiment!.title
        createDateLabel.text = NSDateFormatter.smartStringFormDate(experiment!.createDate!)
    }

}
