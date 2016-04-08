//
//  WatchComplicationSyncProtocol.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/16/16.
//
//

import Foundation
import WatchConnectivity

class watchDataPoint: NSObject, NSCoding {
    //Required
    var key: String? = nil
    var data: NSData? = nil
    var lastUpdatedTime: NSDate? = nil
    init(key: String, data: NSData, lastUpdatedTime: NSDate) {
        self.key = key
        self.data = data
        self.lastUpdatedTime = lastUpdatedTime
    }
    required init?(coder aDecoder: NSCoder) {
        key = aDecoder.decodeObjectForKey("key") as? String
        data = aDecoder.decodeObjectForKey("data") as? NSData
        lastUpdatedTime = aDecoder.decodeObjectForKey("date") as? NSDate
    }
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(key, forKey: "key")
        aCoder.encodeObject(data, forKey: "data")
        aCoder.encodeObject(lastUpdatedTime, forKey: "date")
    }
}

public protocol WatchComplicationDelegate {
    func rebuildData();
    func updateData();
    func updateBucket(bucketName: String);
}

public class watchSyncProtocol {
    
    public static func initProtocol() {
        sharedProtocol.check()
    }
    
    public static let sharedProtocol = watchSyncProtocol.init()
    
    let dataSrcChipher = ProtocolCipher.watchConnectiveCipher
    
    func check() {
    }
    
    //1.0 4 state
    //Sync: watch->phone, for requesting initial packet, with "Init" as callback with seed; foreground update
    //Data: phone->watch, for pushing newest data, with no callback; background update
    //State: phone->watch, move from one bucket to another, request immediate swap on complication; complication update
    
    #if os(watchOS)
    public var complicationDelegate: WatchComplicationDelegate? = nil
    #endif
    
    init() {
        dataSrcChipher.addCallback("Sync") { (key: String, value: AnyObject) in
            #if os(iOS)
                //Send packet
                let packet: NSData
                if let date = value as? NSDate {
                    packet = CacheStorageSpace.commonStorageSpace.syncPacket(date)
                } else {
                    packet = CacheStorageSpace.commonStorageSpace.syncPacket(NSDate(timeIntervalSinceNow: -2*24*60*60.0))
                }
                self.dataSrcChipher.addMessage("Sync", value: packet)
                self.dataSrcChipher.outgoingMessageFlush()
            #endif
            #if os(watchOS)
                if let data = value as? NSData {
                    CacheStorageSpace.commonStorageSpace.syncFromPacket(data)
                    //self.complicationDelegate?.rebuildData()
                    self.complicationDelegate?.updateData()
                }
            #endif
        }
        dataSrcChipher.addCallback("Data") { (key: String, value: AnyObject) in
            #if os(watchOS)
                let value = value as! NSData
                if let dataPt = NSKeyedUnarchiver.unarchiveObjectWithData(value) as? watchDataPoint {
                    CacheStorageSpace.commonStorageSpace.updateKey(dataPt.key!, data: dataPt.data!, lastUpdatedTime: dataPt.lastUpdatedTime!)
                    self.complicationDelegate?.updateData()
                }
                
            #endif
        }
        dataSrcChipher.addCallback("Complication") { (key: String, value: AnyObject) in
            #if os(iOS)
                if let bucketName = value as? String {
                    let bucket: CCStorageBucket? = CCKeyValueStorage.sharedStorage().fetchBucket(bucketName)
                    if let dataSet = bucket?.lastestData(1) {
                        if dataSet.count == 1 {
                            let dataPt = (dataSet as NSOrderedSet).firstObject as! CCData
                            let value = (dataPt.valueForKey("obj") as! NSManagedObject)
                            let pt = watchDataPoint(key: bucketName, data: value.valueForKey("value")as! NSData, lastUpdatedTime: value.valueForKey("insertDate") as! NSDate)
                            let data = NSKeyedArchiver.archivedDataWithRootObject(pt)
                            WatchSession.defaultSession.sendComplicationInfo(["Complication": data])
                        }
                    }
                }
            #endif
            #if os(watchOS)
                let value = value as! NSData
                if let dataPt = NSKeyedUnarchiver.unarchiveObjectWithData(value) as? watchDataPoint,  (_, oldData) = CacheStorageSpace.commonStorageSpace.newestValueForKey(dataPt.key!) {
                    if (!oldData.isEqual(dataPt.data!)) {
                        CacheStorageSpace.commonStorageSpace.updateKey(dataPt.key!, data: dataPt.data!, lastUpdatedTime: dataPt.lastUpdatedTime!)
                        self.complicationDelegate?.updateData()
                    }
                }
            #endif
            debugPrint("Sync complication")
        }
        dataSrcChipher.addCallback("State") { (key: String, value: AnyObject) in
            #if os(watchOS)
                if let bucketName = value as? String {
                    self.complicationDelegate?.updateBucket(bucketName)
                    
                }
            #endif
        }
        WatchSession.defaultSession.sessionInit()
    }
    
    func updateKey(key: String, data: NSData, lastUpdatedTime: NSDate) {
        let pt = watchDataPoint(key: key, data: data, lastUpdatedTime: lastUpdatedTime)
        let packet = NSKeyedArchiver.archivedDataWithRootObject(pt)
        dataSrcChipher.addMessage("Data", value:packet)
        dataSrcChipher.outgoingImmeMessageFlush()
        #if os(iOS)
        WatchSession.defaultSession.sendComplicationInfo([key: packet])
        #endif
    }
    
    #if os(watchOS)
    public func syncPacket() {
        let date = CacheStorageSpace.commonStorageSpace.lastSyncDate()
        if let date = date {
            dataSrcChipher.addMessage("Sync", value: date)
        } else {
            dataSrcChipher.addMessage("Sync", value: [])
        }
        dataSrcChipher.outgoingMessageFlush()
    }
    #endif
    
    public func updatedKey(key: String)->(NSData, NSDate)? {
        if let data = WatchSession.defaultSession.receivedInfo()?[key] as? NSData {
            if let pt = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? watchDataPoint {
                if let data = pt.data, date = pt.lastUpdatedTime {
                    return (data, date)
                }
            }
        }
        return nil
    }
    
}
