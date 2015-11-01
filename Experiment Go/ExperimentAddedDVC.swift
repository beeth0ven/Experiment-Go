//
//  ExperimentAddedDVC.swift
//  Experiment Go
//
//  Created by luojie on 9/23/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit


class ExperimentAddedDVC: ExperimentDetailViewController {

    var done: ((CKExperiment) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editing = true
    }
    
    override func configureBarButtons() {
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItem = doneButtonItem
        navigationItem.rightBarButtonItem?.enabled = false
    }
    
    override func doneClicked() {
        presentingViewController?.dismissViewControllerAnimated(true) { self.done?(self.experiment!) }
    }
    
}