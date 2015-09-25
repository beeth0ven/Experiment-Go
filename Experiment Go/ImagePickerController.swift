//
//  ImagePickerController.swift
//  Experiment Go
//
//  Created by luojie on 9/25/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit

class ImagePickerController: UIImagePickerController {
    
    var done: ((UIImage) -> Void)?

    convenience init(done: (UIImage) -> Void) {
        self.init()
        self.done = done
        self.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.allowsEditing = true
        self.delegate = self
    }


}

extension ImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
//     MARK: - Image Picker Controller Delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as! UIImage
        presentingViewController?.dismissViewControllerAnimated(true) { self.hideStatusBar() ; self.done?(image) }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        presentingViewController?.dismissViewControllerAnimated(true) { self.hideStatusBar() }
    }
    
    private func hideStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
    }
}