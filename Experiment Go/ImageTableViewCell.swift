//
//  ImageTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 8/31/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    
    var profileImageURL: NSURL? { didSet { updateUI() } }
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    var profileImge: UIImage? {
        get { return profileImageView.image }
        set { profileImageView.image = newValue }
    }
    
    
    func updateUI() {
        profileImge = nil
        guard let url = profileImageURL else { return }
        UIImage.fetchImageForURL(url) { (image) in self.profileImge = image }
    }
    

}
