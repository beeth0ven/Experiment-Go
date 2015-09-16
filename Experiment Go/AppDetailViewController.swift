//
//  AppDetailViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/15/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class AppDetailViewController: UIViewController {
    
    var adapted = false { didSet { configureBarButtons() } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBarButtons()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(true)
    }
    
    func configureBarButtons() {  navigationItem.leftBarButtonItem = adapted ? closeBarButtonItem : nil }
}
