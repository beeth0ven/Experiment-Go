//
//  ReviewViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/3/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ReviewViewController: RecordDetailViewController {
    
    
    // MARK: - Properties

    var review: CKRecord? {
        get { return record }
        set { record = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUI()
    }
    
    override func configureBarButtons() {
        super.configureBarButtons()
        navigationItem.leftBarButtonItem?.title = "Cancel"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bodyTextView.becomeFirstResponder()
    }
    
    // MARK: - View Configure
    @IBOutlet weak var bodyTextView: UITextView! {
        didSet {
            bodyTextView.delegate = self
        }
    }

    func updateUI() {
        bodyTextView?.text = review?[ReviewKey.Body] as? String
    }
    
}

extension ReviewViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        review![ReviewKey.Body] = textView.text
    }
    
}
