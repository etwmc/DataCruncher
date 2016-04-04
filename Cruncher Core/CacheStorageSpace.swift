//
//  CacheStorageSpace.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/12/16.
//
//

import Foundation
import CoreData

public class CacheObjectData: NSObject {
    public let value: NSData
    public let insertDate: NSDate
    init(value: NSData, _ insertDate: NSDate) {
        self.value = value
        self.insertDate = insertDate
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

public class CacheStorageSpace: NSObject {
    
    public static let commonStorageSpace = CacheStorageSpace()
    
    public override init() {
        #if os(watchOS)
            dispatch_async(dispatch_get_main_queue()) {
                watchSyncProtocol.sharedProtocol.syncPacket()
            }
        #endif
    }
    
    private let dispatchQueue = dispatch_queue_create("Cache Queue", DISPATCH_QUEUE_CONCURRENT)
    
    private func storageURL()->NSURL {
        let folder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let folderURL = NSURL(fileURLWithPath: folder, isDirectory: true)
        return folderURL.URLByAppendingPathComponent("cache")
    }
    
    private func storageObject()->[String: [NSDate: NSData]] {
        let url = self.storageURL()
        if let data = NSData(contentsOfURL: url) {
            if let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: [NSDate: NSData]] {
                return dict
            }
        }
        return [:]
    }
    
    private func setStorageObject(obj: [String: [NSDate: NSData]]) {
        
        var trimmedObj: [String: [NSDate: NSData]] = [:]
        
        for a: (String, [NSDate: NSData]) in obj {
            let key = a.0
            let val = a.1.filter({ (value: (NSDate, NSData)) -> Bool in
                return value.0.timeIntervalSinceNow*(-1.0) < 7*24*60*60.0
            }).sort({ (a: (NSDate, NSData), b: (NSDate, NSData)) -> Bool in
                return a.0.compare(b.0) == NSComparisonResult.OrderedAscending
            }).reduce([:], combine: { (t: [NSDate: NSData], v: (NSDate, NSData)) -> [NSDate: NSData] in
                var _t = t
                _t[v.0] = v.1
                return _t
            })
            trimmedObj[key] = val
        }
        
        let url = self.storageURL()
        let data = NSKeyedArchiver.archivedDataWithRootObject(trimmedObj)
        data.writeToURL(url, atomically: true)
    }
    
    public func allKeys()->[String] {
        return Array(storageObject().keys.sort())
    }
    
    public func updateKey(key: String, data: NSData, lastUpdatedTime: NSDate) {
        dispatch_barrier_async(dispatchQueue) { 
            var objs = self.storageObject()
            
            if var bucket = objs[key] {
                bucket[lastUpdatedTime] = data
                objs[key] = bucket
            } else {
                objs[key] = [lastUpdatedTime: data]
            }
            
            self.setStorageObject(objs)
            
        }
    }
    
    public func newestValueForKey(key: String)->(NSDate, NSData)? {
        var value: (NSDate, NSData)? = nil
        dispatch_sync(dispatchQueue) {
            let objs = self.storageObject()
            if let values = objs[key] {
                let sortedValue = values.sort({ (a: (NSDate, NSData), b: (NSDate, NSData)) -> Bool in
                    return (a.0.compare(b.0) == .OrderedDescending)
                })
                value = sortedValue.first
            }
        }
        return value
    }
    public func allValuesForKey(key: String)->[NSDate: NSData]? {
    var value: [NSDate: NSData]? = nil
        dispatch_sync(dispatchQueue) {
            let objs = self.storageObject()
            value = objs[key]
        }
        return value
    }
    
    public func lastSyncDate()->NSDate? {
        var date: NSDate?
        dispatch_sync(dispatchQueue) {
            let url = self.storageURL()
            if let dict = NSDictionary(contentsOfURL: url.URLByAppendingPathExtension("conf.plist")) {
                date = dict["Last Sync"] as? NSDate
            }
        }
        return date
    }
    
    func syncPacket(lastSyncDate: NSDate, timeframe: NSTimeInterval = 24*60*60.0)->NSData {
        
        let copies = self.storageObject().mapValues { (input: [NSDate : NSData]) -> [NSDate: NSData] in
            let keys = input.keys.filter({ (date: NSDate) -> Bool in
                return (date.compare(lastSyncDate) == .OrderedDescending) && (date.timeIntervalSinceNow * -1.0 < timeframe)
            })
            var tmp: [NSDate: NSData] = [:]
            for key in keys {
                tmp[key] = input[key]
            }
            return tmp
        }
        var finalResult: [String:[NSDate: NSData]] = [:]
        CCStorageContextManager.sharedManager().waitForImport()
        for (key, values) in copies {
            //Only sync 24 hours
            //From backend
            var subArray: [NSDate: NSData] = values
            if let bucket = self.backendBucket(key) {
                let predicate = NSPredicate(format: "self.insertDate.timeIntervalSinceNow > %@", -5*24*60*60 as NSNumber)
                if let dataSet = bucket.dataFilteredWithPredicate(predicate).array as? [CCData] {
                    for data in dataSet {
                        if let date = data.valueForKeyPath("obj.insertDate") as? NSDate,  rawData = data.valueForKeyPath("obj.value") as? NSData {
                            subArray[date] = rawData
                        }
                    }
                }
            }
            
            finalResult[key] = subArray
            
        }
        return NSKeyedArchiver.archivedDataWithRootObject(finalResult)
    }
    
    func syncFromPacket(syncData: NSData, timeframe: NSTimeInterval = 2*60*60.0) {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(syncData) as! [String: [NSDate: NSData] ]
        dispatch_barrier_async(dispatchQueue) {
            var objs = self.storageObject()
            for bucketDelta in dict {
                if var bucket = objs[bucketDelta.0] {
                    bucket.update(bucketDelta.1)
                    objs.updateValue(bucket, forKey: bucketDelta.0)
                } else {
                    objs[bucketDelta.0] = bucketDelta.1
                }
            }
            self.setStorageObject(objs)
        }
    }
    
    func backendBucket(bucketName: String)->CCStorageBucket? {
        let kvs = CCKeyValueStorage.sharedStorage()
        return kvs.fetchBucket(bucketName)
    }
    
}