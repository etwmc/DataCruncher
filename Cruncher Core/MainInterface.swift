//
//  MainInterface.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 1/1/16.
//
//

import Foundation
#if os(iOS)||os(OSX)
    import CloudKit
#endif

private func handleDeviceConsolidate(userInfo: [NSObject: AnyObject]) {
    #if os(iOS)
        let consolidate = DeviceConsolidate.shareConsolidate
        consolidate.handleNotification(userInfo)
    #endif
}

private func handleBucketUpdate(userInfo: [NSObject: AnyObject]) {
    #if !os(watchOS)
        let manager = bucketMonitorManger.sharedManager
        let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
        if let record = notification.recordID {
            if (true) {
                //Update the bucket data to place it monitor
                //First, the notification
                //Then, update the data at watch
                #if os(iOS)
                    CKHelperFunction().getDatabase(true).fetchRecordWithID(record, completionHandler:{
                        (record: CKRecord?, error: NSError?) -> Void in
                        if let data = record?.objectForKey("data") as? NSData, let bucketName = record?.objectForKey("bucketName") as? String, let date = record?.objectForKey("updateTime") as? NSDate {
                            NSLog("Push: %@", bucketName)
                            //Update the bucket and watch
                            CacheStorageSpace.commonStorageSpace.updateKey(bucketName, data: data, lastUpdatedTime: date)
                            watchSyncProtocol.sharedProtocol.updateKey(bucketName, data: data, lastUpdatedTime: date)
                        }
                    })
                    
                #endif
            }
        }
    #endif
}

private func handleContainerUpdate(userInfo: [NSObject: AnyObject]) {
    #if !os(watchOS)
        CCProcessorContainerManager.sharedManager.containerManagerNotification(userInfo)
    #endif
}

public func handleFrameworkRemoteNotifcation(userInfo: [NSObject: AnyObject], otherNotification: ([NSObject: AnyObject])->Void) {
    let apsDict = userInfo["aps"] as? [String: NSObject]
    if let apsDict = apsDict {
        switch apsDict["category"]! {
        case "Device_Change":
            handleDeviceConsolidate(userInfo)
            return
        case "Bucket_Update":
            handleBucketUpdate(userInfo)
            return
        case "Container_Update":
            handleContainerUpdate(userInfo)
        default:
            break
        }
        
    }
    otherNotification(userInfo)
}

#if !os(watchOS)
public class bucketMonitorManger: NSObject {
    var buckets: [String: String] = [:]
    public static let sharedManager = bucketMonitorManger()
    public func registerBucketMonitor(bucket:CCStorageBucket) {
        buckets[bucket.recordID.recordName] = bucket.bucketName
        let data = (bucket.lastestData(1).objectAtIndex(0) as! CCData).valueForKeyPath("obj.value")
        do {
            let unwrapData = try NSJSONSerialization.JSONObjectWithData(data as! NSData, options: NSJSONReadingOptions.AllowFragments) as! [String : NSObject]
            for (key, value) in unwrapData {
                #if os(iOS)
                #endif
            }
            
        } catch {
            
        }
    }
    public func deregisterBucketMonitor(bucket:CCStorageBucket) {
        buckets.removeValueForKey(bucket.recordID.recordName)
    }
    public func bucketIsMonitored(recordID: CKRecordID)->Bool {
        return (buckets.indexForKey(recordID.recordName) != nil)
    }
    public func bucketName(recordID: CKRecordID)->String? {
        return buckets[recordID.recordName]
    }
}
#endif

#if os(iOS)
    public func syncData() {
        let addr = CCStorage.historyDBAddr()
        
    }
#endif