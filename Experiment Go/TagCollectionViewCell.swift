//
//  TagCollectionViewCell.swift
//  Experiment Go
//
//  Created by luojie on 9/13/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TagCollectionViewCell: UICollectionViewCell {
    
    var title: String?          { didSet { updateUI() } }
    var type: Type = .Normal    { didSet { updateUI() } }
    
    override func awakeFromNib() { super.awakeFromNib() ; layer.borderColor = DefaultStyleController.Color.Sand.CGColor }
    
    @IBOutlet weak var button: UIButton!
    
    func updateUI() {
        switch type {
        case .Normal:
            button.setTitle(title, forState: .Normal)
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            backgroundColor = DefaultStyleController.Color.Sand
        case .Add:
            button.setTitle("+", forState: .Normal)
            button.setTitleColor(DefaultStyleController.Color.Sand, forState: .Normal)
            backgroundColor = UIColor.clearColor()
        }
    }
    
    enum Type {
        case Normal
        case Add
    }
    
}
