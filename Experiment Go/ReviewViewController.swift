//
//  ReviewViewController.swift
//  Experiment Go
//
//  Created by luojie on 8/3/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class ReviewViewController: ItemDetailViewController {
    
    
    // MARK: - Properties

    var review: CKLink? {
        get { return item as? CKLink }
        set { item = newValue }
    }
    
    var done: ((CKLink) -> Void)?
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bodyTextView.becomeFirstResponder()
    }
    
    // MARK: - View Configure

    override func configureBarButtons() {
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
        navigationItem.rightBarButtonItem?.enabled = false
    }
    @IBOutlet weak var bodyTextView: UITextView!

    func updateUI() { bodyTextView?.text = review?.content }
    
    
    override func doneClicked() {
        presentingViewController?.dismissViewControllerAnimated(true) { done?(review!) }
    }
}

extension ReviewViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        review!.content = textView.text
        navigationItem.rightBarButtonItem?.enabled = true
    }
    
}
