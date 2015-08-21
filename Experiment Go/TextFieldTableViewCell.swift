//
//  TextFieldTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.enabled = false
//            textField.delegate = self
//            oberveTextField()
        }
    }
    
    deinit {
//        stopOberveTextField()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        textField.text = ""
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            textField.becomeFirstResponder()
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        textField.enabled = superTableViewIsEditing()
    }

}

extension UITableViewCell {
    func superTableViewIsEditing() -> Bool {
        var view: UIView? = self
        repeat {
            view = view!.superview
            if view == nil { break }
            if view is UITableView { break }
        } while true
        
        return view == nil ? false : (view as! UITableView).editing
    }
}

//extension TextFieldTableViewCell: UITextFieldDelegate {
//    
//    // MARK: - Text Field Delegate
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
//    
//    @objc private func handleTextFieldTextDidChange(notification: NSNotification) {
//        guard let textField = notification.object as? UITextField else { return }
//        objectValue?.value = textField.text
//    }
//    
//    private func oberveTextField() {
//        let center = NSNotificationCenter.defaultCenter()
//        center.addObserver(self,
//            selector: "handleTextFieldTextDidChange:",
//            name: UITextFieldTextDidChangeNotification,
//            object: textField
//        )
//    }
//    
//    private func stopOberveTextField() {
//        let center = NSNotificationCenter.defaultCenter()
//        center.removeObserver(self)
//    }
//    
//}
