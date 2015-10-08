//
//  FollowUserTableViewCell.swift
//  Experiment Go
//
//  Created by luojie on 10/3/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import UIKit
import CloudKit

class FollowUserTableViewCell: UserTableViewCell {
    
    var handleFail: ((NSError) -> Void)?
    var didAuthoriseElseRequest: (((Void) -> Void)? -> Bool)?

    override func updateUI() {
        super.updateUI()
        followButton.on = CKUsers.AmIFollowingTo(user!)
    }
    
    @IBOutlet weak var followButton: SwitchButton!
    
    @IBAction func followClicked(sender: SwitchButton) {
        guard didAuthoriseElseRequest!({ self.followClicked(sender) }) else { return }
        !sender.on ? doFollow(sender) : doUnfollow(sender)
        sender.on = !sender.on
    }
    
    
    private func doFollow(sender: SwitchButton) {
        CKUsers.FollowUser(user!,
            didFail: {
                self.handleFail?($0)
                sender.on = !sender.on
            }
        )
    }
    
    private func doUnfollow(sender: SwitchButton) {
        CKUsers.UnfollowUser(user!,
            didFail: {
                self.handleFail?($0)
                sender.on = !sender.on
            }
        )
        
    }

}