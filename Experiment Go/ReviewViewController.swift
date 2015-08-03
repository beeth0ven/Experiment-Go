//
//  ReviewViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/3/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData

class ReviewViewController: UITableViewController {
    
    
    // MARK: - Properties
    
    var review: Review? {
        get {
            return detailItem as? Review
        }
        
        set {
            detailItem = newValue
        }
    }
    
    var detailItem: RootObject! {
        didSet {
            // Update the view.
            updateUI()
        }
        
    }
    
    @IBOutlet weak var bodyTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUI()
        hideBarSeparator()
    }
    
    // MARK: - View Configure
    
    func updateUI() {
        bodyTextView?.text = review?.body
    }
    
    
}
