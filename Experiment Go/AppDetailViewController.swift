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
        navigationController?.delegate = self
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setBarSeparatorHidden(true)
    }
    
    func configureBarButtons() {  navigationItem.leftBarButtonItem = adapted ? closeBarButtonItem : nil }
}

extension AppDetailViewController: UINavigationControllerDelegate {
    
    override var preferredContentSize: CGSize {
        get { return view.systemLayoutSizeFittingSize(super.preferredContentSize).expandBy(width: 0, height: 50) }
        set { super.preferredContentSize = newValue }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        navigationController.preferredContentSize = viewController.preferredContentSize
    }
}

extension CGSize {
    func expandBy(width width: CGFloat, height: CGFloat) -> CGSize {
        return CGSize(width: self.width + width, height: self.height + height)
    }
}