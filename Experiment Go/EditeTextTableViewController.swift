//
//  EditeTextTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/1/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EditeTextTableViewController: EditeValueTableViewController {
    
    // MARK: - Properties
    
    var text: String? {
        get { return value as? String }
        set { value = newValue }
    }
    
    

    var done: ((String?) -> ())?

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bodyTextView.becomeFirstResponder()
    }
    
    override func doneClicked() {
        bodyTextView.resignFirstResponder()
        done?(text)
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - View Configure
    @IBOutlet weak var bodyTextView: UITextView! { didSet { bodyTextView.delegate = self } }
    
    override func updateUI() { bodyTextView?.text = text }
    
}

extension EditeTextTableViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        text = textView.text
        navigationItem.rightBarButtonItem?.enabled = true
    }
}

