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

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        navigationController?.setNavigationBarHidden(false, animated: true)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        bodyTextView.becomeFirstResponder()
    }

    
    // MARK: - View Configure
    @IBOutlet weak var bodyTextView: UITextView! { didSet { bodyTextView.delegate = self } }
    
    func updateUI() {
        bodyTextView?.text = text
    }
    
    
    var doneBlock: (() -> ())?
    
    @IBAction func done(sender: UIBarButtonItem) {
        bodyTextView.resignFirstResponder()
        doneBlock?()
        navigationController?.popViewControllerAnimated(true)
    }
    
}

extension EditeTextTableViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        text = textView.text
    }
}