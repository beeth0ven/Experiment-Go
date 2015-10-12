//
//  EditeValueTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EditeValueTableViewController: UITableViewController {
    
    // MARK: - Properties
    var value: AnyObject? 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureBarButtons()
        showOrHideToolBarIfNeeded()
        hideNavigationBar()
    }
    
    private func hideNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func updateUI() { }
    func configureBarButtons() {
        navigationItem.rightBarButtonItem = doneButtonItem
        navigationItem.rightBarButtonItem?.enabled = false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

