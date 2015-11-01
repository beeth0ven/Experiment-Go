//
//  AppDelegate.swift
//  Experiment Go
//
//  Created by luojie on 7/10/15.
//  Copyright (c) 2015 LuoJie. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, iCloudKeyValueStoreHasChangeObserver {
    
    struct Cache { static let Manager = CacheManager() }

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        DefaultStyleController.applyStyle()
        startObserveiCloudKeyValueStoreHasChange()
//        CKUsers.UpdateCurrentUser()
        return true
    }
    
      func applicationWillTerminate(application: UIApplication) {
        stopObserve()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("Successfully to Register For Remote Notifications.")

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Fail To Register For Remote Notifications: \(error.localizedDescription)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSNotificationCenter.defaultCenter().postNotificationName(Notification.remoteNotification.rawValue, object: nil)
        print("didReceiveRemoteNotification.")
    }
    
//    func requestApplicationPermission() {
//        getDiscoverabilityPermission(
//            didGet: { _ in CKUsers.UpdateCurrentUser() },
//            didFail: nil
//        )
//    }
    
//    func getDiscoverabilityPermission(didGet didGet: (Bool) -> Void, didFail: ((NSError) -> Void)?) {
//        CKContainer.defaultContainer().requestApplicationPermission(.UserDiscoverability) {
//            (applicationPermissionStatus, error)  in
//            Queue.Main.execute { error != nil ? didFail?(error!) : didGet( applicationPermissionStatus == .Granted ) }
//        }
//    }
//    
    static func requestForRemoteNotifications() {
        let type: UIUserNotificationType = [.Alert, .Badge, .Sound]
        let settings = UIUserNotificationSettings(forTypes:type , categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        CKUsers.saveCurrentUserSubscriptionsIfNeeded()
    }
    
    func iCloudKeyValueStoreHasChange(notification: NSNotification) {
        guard let changedKeys = (notification.userInfo as! Dictionary<String,AnyObject>)[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        guard changedKeys.contains(CKUsers.Key.CurrentUser.rawValue) else { return }
        CKUsers.UpdateCurrentUserFromiCloudKVS()
    }
}




