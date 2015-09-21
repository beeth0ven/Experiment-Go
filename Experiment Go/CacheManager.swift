//
//  CacheManager.swift
//  Experiment Go
//
//  Created by luojie on 8/20/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation
import CloudKit
import UIKit


class CacheManager {
    
    func cacheAssetData(data: NSData ,forURL url: NSURL) {
        let cachedUrl = localCachedURLforURL(url)
        guard fileExistsAtURL(cachedUrl) == false else { return }
        fileManager.createFileAtPath(cachedUrl.path!, contents: data, attributes: nil)
        cleanupOldFiles()
        print("Fetch image from cloud.")
    }
    
    func assetDataForURL(url: NSURL) -> NSData? {
        let cachedUrl = localCachedURLforURL(url)
        guard fileExistsAtURL(cachedUrl) else { return nil }

        do {
            try fileManager.setAttributes([NSFileModificationDate: NSDate()], ofItemAtPath: cachedUrl.path!)
        } catch {
            abort()
        }
//        print("Fetch image from cache.")
        return NSData(contentsOfURL: cachedUrl)
    }
    
    
    private let fileManager = NSFileManager()
    
    private var assetCacheFolder: NSURL {
        let cacheDirectory = fileManager.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
        let result = cacheDirectory.URLByAppendingPathComponent("CKAsset", isDirectory: true)
        var isDir : ObjCBool = false
        if (!fileManager.fileExistsAtPath(result.path!, isDirectory: &isDir)) {
            do {
                try fileManager.createDirectoryAtURL(result, withIntermediateDirectories: true, attributes: nil)
            } catch {
                abort()
            }
           
        }
        return result
    }
    
    private func fileExistsAtURL(url: NSURL) -> Bool { return fileManager.fileExistsAtPath(url.path!) }
    
    private func localCachedURLforURL(url: NSURL) -> NSURL { return assetCacheFolder.URLByAppendingPathComponent(url.pathExtension!) }
    
    // Cache size 20M
    private var cacheSize = 20 * 1024 * 1024
    
    private func cleanupOldFiles() {
        let dirEnumerator = fileManager.enumeratorAtURL(assetCacheFolder,
            includingPropertiesForKeys: [NSURLAttributeModificationDateKey],
            options: .SkipsHiddenFiles,
            errorHandler: nil)!
        
        struct File {
            var fileSize: NSNumber
            var fileDate: NSDate
            var url: NSURL
        }
        
        var fileSize: AnyObject?
        var fileDate: AnyObject?
        var files = [File]()
        var dirSize: Int {
            let reslut = files.reduce(0) { $1.fileSize.integerValue }
            print("CacheDirSize: \(reslut/1024)KB")
            return reslut
        }
        
        for url in dirEnumerator.allObjects as! [NSURL] {
            do {
                try url.getResourceValue(&fileSize, forKey: NSURLFileSizeKey)
                try url.getResourceValue(&fileDate, forKey: NSURLAttributeModificationDateKey)
            } catch {
                abort()
            }
            let file = File(fileSize: fileSize as! NSNumber, fileDate:  fileDate as! NSDate, url: url)
            files.append(file)
            print("file Size: \(file.fileSize.integerValue/1024)KB")
//            print("file url: \(file.url)")
            
        }
        
        files.sortInPlace { $0.fileDate > $1.fileDate }
        while dirSize > cacheSize {
            let file = files.last!
            do {
                try fileManager.removeItemAtURL(file.url)
            } catch {
                abort()
            }
            files.removeLast()
        }
        

    }
    

}

