//
//  SwitchButton.swift
//  Experiment Go
//
//  Created by luojie on 10/3/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//


import UIKit

@IBDesignable

class SwitchButton: UIButton {
    
    var on = false { didSet { updateUI() } }
    
    @IBInspectable
    var onStateTitle: String = "On".localizedString
    
    @IBInspectable
    var offStateTitle: String = "Off".localizedString
    
    var color: UIColor = UIColor.globalTintColor()
    
    func updateUI() {
        if on == false {
            // Default case here
            setTitle(offStateTitle, forState: .Normal)
            tintColor = color
            backgroundColor = nil
            
        } else {
            setTitle(onStateTitle, forState: .Normal)
            tintColor = UIColor.whiteColor()
            backgroundColor = color
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        return super.intrinsicContentSize().sizeByDelta(dw:25, dh: 0)
    }
}

extension CGSize {
    func sizeByDelta(dw dw:CGFloat, dh:CGFloat) -> CGSize {
        return CGSizeMake(self.width + dw, self.height + dh)
    }
}