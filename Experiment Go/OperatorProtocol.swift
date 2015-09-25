////
////  OperatorProtocol.swift
////  Experiment Go
////
////  Created by luojie on 9/24/15.
////  Copyright © 2015 LuoJie. All rights reserved.
////
//
//import Foundation
//import CloudKit
//
//// MARK: - CloudDatabaseOperator
//
//protocol CloudDatabaseOperator {
//    static var publicCloudDatabase: CKDatabase { get }
//    var publicCloudDatabase: CKDatabase { get }
//}
//
//extension CloudDatabaseOperator {
//    static var publicCloudDatabase: CKDatabase { return CKContainer.defaultContainer().publicCloudDatabase }
//    var publicCloudDatabase: CKDatabase { return CKContainer.defaultContainer().publicCloudDatabase }
//}
//
//// MARK: - NotificationCenterOperator
//
//protocol NotificationCenterOperator {
//    static var notificationCenter: NSNotificationCenter { get }
//    var notificationCenter: NSNotificationCenter { get }
//}
//
//extension NotificationCenterOperator {
//    static var notificationCenter: NSNotificationCenter { return NSNotificationCenter.defaultCenter() }
//    var notificationCenter: NSNotificationCenter { return NSNotificationCenter.defaultCenter() }
//}
//
//
//// MARK: - UbiquitousKeyValueStore
//
//protocol UbiquitousKeyValueStoreOperator {
//    static var iCloudKeyValueStore: NSUbiquitousKeyValueStore { get }
//    var iCloudKeyValueStore: NSUbiquitousKeyValueStore { get }
//}
//
//extension UbiquitousKeyValueStoreOperator {
//    static var iCloudKeyValueStore: NSUbiquitousKeyValueStore { return NSUbiquitousKeyValueStore.defaultStore() }
//    var iCloudKeyValueStore: NSUbiquitousKeyValueStore { return NSUbiquitousKeyValueStore.defaultStore() }
//}
//
