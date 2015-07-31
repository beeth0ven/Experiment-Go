//
//  TextFieldTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: ObjectValueTableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.enabled = false
            textField.delegate = self
            oberveTextField()
        }
    }
    
    deinit {
        stopOberveTextField()
    }
    
    override func updateUI() {
        titleLabel.text = ""
        textField.text = ""
        textField.enabled = false
        guard let objectValue = objectValue else { return }
        titleLabel.text = objectValue.key.capitalizedString
        textField.text = objectValue.value as? String 
    }
    
    private func superTableViewIsEditing() -> Bool {
        var view: UIView? = self
        repeat {
            view = view!.superview
            if view == nil { break }
            if view is UITableView { break }
        } while true
        
        return view == nil ? false : (view as! UITableView).editing
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            let editing = superTableViewIsEditing()
            textField.enabled = editing
            textField.becomeFirstResponder()
        }
    }

}

extension TextFieldTableViewCell: UITextFieldDelegate {
    
    // MARK: - Text Field Delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func handleTextFieldTextDidChange(notification: NSNotification) {
        guard let textField = notification.object as? UITextField else { return }
        objectValue?.value = textField.text
    }
    
    private func oberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self,
            selector: "handleTextFieldTextDidChange:",
            name: UITextFieldTextDidChangeNotification,
            object: textField
        )
    }
    
    private func stopOberveTextField() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }
    
}
