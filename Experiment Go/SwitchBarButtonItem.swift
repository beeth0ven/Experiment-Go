//
//  SwitchBarButtonItem.swift
//  Experiment Go
//
//  Created by luojie on 8/5/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

@IBDesignable

class SwitchBarButtonItem: UIBarButtonItem {
    
    var on = false { didSet { updateUI() } }
    
    @IBInspectable
    var onStateTitle: String = "On"
    
    @IBInspectable
    var offStateTitle: String = "Off"
    
    var color: UIColor = UIColor.globalTintColor()
  
    func updateUI() {
        var backgroundImage: UIImage?
        
        if on == false {
            // Default case here
            title = offStateTitle
            tintColor = color
            backgroundImage = nil

        } else {
            title = onStateTitle
            tintColor = UIColor.whiteColor()
            backgroundImage = UIImage.resizableImageFromColor(color, cornerRadius: 5)
        }
        
        setBackgroundImage(backgroundImage,
            forState: .Normal,
            barMetrics: .Default
        )
    }
}