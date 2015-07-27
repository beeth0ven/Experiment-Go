//
//  TextFieldTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/16/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {
    
    var detailItem: RootObect? { didSet { updateUI() } }
    
    var stringKey: String? { didSet { updateUI() } }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.enabled = false
            textField.delegate = self
            oberveTextField()
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    deinit {
        stopOberveTextField()
    }
    
    func updateUI() {
        titleLabel.text = ""
        textField.text = ""
        guard let detailItem = detailItem else { return }
        guard let stringKey = stringKey else { return }
        titleLabel.text = stringKey
        textField.text = (detailItem.valueForKey(stringKey) as? CustomStringConvertible)?.description
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
        let editing = superTableViewIsEditing()
        textField.enabled = editing
        if selected {
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
        guard let detailItem = detailItem else { return }
        detailItem.setValue(textField.text, forKey: titleLabel.text!)
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
