//
//  AuthorTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 7/30/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class UserTableViewCell: RecordTableViewCell {
    
    var user: CKRecord? {
        guard record != nil else { return nil }
        switch record!.recordType {
        case CKRecordTypeUserRecord:
            return record!
        default:
            return record!.createdBy        }
        
    }
    
    var profileImage: UIImage? {
        get {
            return profileImageView.image
        }
        set {
            profileImageView.image = newValue
        }
    }
    
    var profileImageURL: NSURL? {
        return (user?[UserKey.ProfileImageAsset] as? CKAsset)?.fileURL
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    override func updateUI() {
        profileImage = nil

        nameLabel.text = user?[UserKey.DisplayName] as? String
        
        guard let url = profileImageURL else { return }
        if let imageData = AppDelegate.Cache.Manager.assetDataForURL(url) {
            profileImage = UIImage(data: imageData)
        } else {
            let qos = QOS_CLASS_USER_INITIATED
            dispatch_async(dispatch_get_global_queue(qos, 0)) {
                guard let imageData = NSData(contentsOfURL: url) else { return }
                AppDelegate.Cache.Manager.cacheAssetData(imageData, forURL: url)
                guard url == self.profileImageURL else { return }
                dispatch_async(dispatch_get_main_queue()) {
                    self.profileImage = UIImage(data: imageData)
                }
            }
        }
        
      
        
    }

}