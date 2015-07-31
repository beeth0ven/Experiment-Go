//
//  ImageTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/29/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ImageTableViewCell: ObjectValueTableViewCell {
    
    override func updateUI() {
        textLabel?.text = ""
        guard let objectValue = objectValue else { return }
        textLabel?.text = objectValue.key.capitalizedString
        imageView?.image = objectValue.image ?? UIImage.defultTestImage()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.height * 3/4
        imageView!.bounds.size = CGSizeMake(size, size)
        imageView!.layer.cornerRadius = imageView!.bounds.size.height / 2
        imageView!.layer.masksToBounds = true
    }
}

extension UIImage {
    class func defultTestImage() -> UIImage {
        return UIImage(named: "BlackCat")!
    }
    
}