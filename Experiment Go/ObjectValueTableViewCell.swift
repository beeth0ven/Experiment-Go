//
//  ObjectValueTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit


class ObjectValueTableViewCell: UITableViewCell {
    
    var objectValue: ObjectValue? {
        
        willSet {
            stopObserve()
        }
        
        didSet {
            updateUI()
            startObserve()
        }
    }

    func updateUI() { }
    
    
    
    // MARK: - Key Value Observe
    

    func startObserve() {
        if objectValue != nil {
            objectValue!.rootObject.addObserver(self,
                forKeyPath: objectValue!.key,
                options: .New,
                context: nil)
        }
    }
    
    override func observeValueForKeyPath(
        keyPath: String?,
        ofObject object: AnyObject?,
        change: [String : AnyObject]?,
        context: UnsafeMutablePointer<Void>) {
            updateUI()
    }
    
    func stopObserve() {
        if objectValue != nil {
            objectValue!.rootObject.removeObserver(self, forKeyPath: objectValue!.key)
        }
    }
    
    deinit {
        stopObserve()
    }
    
}