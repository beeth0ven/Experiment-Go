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

class AppDelegate: UIResponder, UIApplicationDelegate  {
    
    struct Cache { static let Manager = CacheManager() }

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        requestForRemoteNotifications()
        DefaultStyleController.applyStyle()
//        CKUsers.updateCurrentUser()
        return true
    }
    
    func requestForRemoteNotifications() {
        let type: UIUserNotificationType = [.Alert, .Badge, .Sound]
        let settings = UIUserNotificationSettings(forTypes:type , categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        print("Successfully to Register For Remote Notifications.")

    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("Fail To Register For Remote Notifications: \(error.localizedDescription)")
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("didReceiveRemoteNotification.")
    }
    
    

}


