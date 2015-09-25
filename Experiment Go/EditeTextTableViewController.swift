//
//  EditeTextTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/1/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EditeTextTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var text: String? { didSet { updateUI() } }
    var done: ((String?) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        navigationItem.rightBarButtonItem = doneButtonItem
        navigationItem.rightBarButtonItem?.enabled = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
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
    
    func updateUI() { bodyTextView?.text = text }
}

extension EditeTextTableViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        text = textView.text
        navigationItem.rightBarButtonItem?.enabled = true
    }
}
