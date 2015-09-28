//
//  EditeImageTableViewController.swift
//  Experiment Go
//
//  Created by luojie on 9/28/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class EditeImageTableViewController: EditeValueTableViewController {
    
    var image: UIImage? {
        get { return value as? UIImage }
        set { value = newValue }
    }
    
    var done: ((UIImage) -> Void)?
    
    override func doneClicked() {
        done?(image!)
        navigationController?.popViewControllerAnimated(true)
    }
    

    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            // Add corner radius
            imageView.layer.cornerRadius = imageView.bounds.size.height / 2
            imageView.layer.masksToBounds = true
        }
    }
    
    override func updateUI() { imageView?.image = image }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let type = UIImagePickerControllerSourceType(rawValue: indexPath.row)!
        presentImagePickerControllerWithSourceType(type)
       
    }
    
    func presentImagePickerControllerWithSourceType(sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            picker.allowsEditing = true
            picker.modalPresentationStyle = .CurrentContext
            presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var tableHeaderContentViewHeightConstraint: NSLayoutConstraint! {
        didSet { tableHeaderViewDefualtHeight = tableHeaderContentViewHeightConstraint.constant }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = tableHeaderViewDefualtHeight! - scrollView.contentOffset.y
        tableHeaderContentViewHeightConstraint.constant = max(40, height)
    }
    
    private var tableHeaderViewDefualtHeight: CGFloat?
    

}

extension EditeImageTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    //     MARK: - Image Picker Controller Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as! UIImage
        dismissViewControllerAnimated(true) {
            self.image = image
            self.navigationItem.rightBarButtonItem?.enabled = true
            self.hideStatusBar()
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) { self.hideStatusBar() }
    }
    
    private func hideStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
    }
}