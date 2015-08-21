////
////  RootObjectTableViewCell.swift
////  Experiment Go
////
////  Created by luojie on 7/28/15.
////  Copyright © 2015 LuoJie. All rights reserved.
////
//
//import UIKit
//
//
//class RootObjectTableViewCell: UITableViewCell {
//    
//    var detailItem: RootObject? { didSet { updateUI() } }
//    
//    func updateUI() {
//        textLabel?.text = detailItem?.entity.name
//        let dateFormatter = NSDateFormatter()
//        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
//        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
//        detailTextLabel?.text = detailItem?.creationDate == nil ?  nil : dateFormatter.stringFromDate(detailItem!.creationDate!)
//    }
//    
//}