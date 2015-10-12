//
//  Notification.swift
//  Experiment Go
//
//  Created by luojie on 10/10/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

enum Notification: String {
    case currentUserHasChange
    case remoteNotification
}

protocol RemoteNotificationObserver: class {
    func startObserveRemoteNotification()
    func stopObserve()
    func didReceiveRemoteNotification(notification: NSNotification)
}

extension RemoteNotificationObserver {
    func startObserveRemoteNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "didReceiveRemoteNotification:",
            name: Notification.remoteNotification.rawValue,
            object: nil
        )
    }
    
    func stopObserve() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}


protocol iCloudKeyValueStoreHasChangeObserver: class {
    func startObserveiCloudKeyValueStoreHasChange()
    func stopObserve()
    func iCloudKeyValueStoreHasChange(notification: NSNotification)
}

extension iCloudKeyValueStoreHasChangeObserver {
    func startObserveiCloudKeyValueStoreHasChange() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "iCloudKeyValueStoreHasChange:",
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.defaultStore()
        )
        NSUbiquitousKeyValueStore.defaultStore().synchronize()
    }
    
    func stopObserve() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

protocol CurrentUserHasChangeObserver: class {
    func startObserveCurrentUserHasChange()
    func stopObserve()
    func updateUI()
}

extension CurrentUserHasChangeObserver {
    func startObserveCurrentUserHasChange() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateUI",
            name: Notification.currentUserHasChange.rawValue,
            object: nil
        )
    }
    
    func stopObserve() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
