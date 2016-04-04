//
//  CKHelperFunction.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 1/2/16.
//
//

import Foundation
#if !TARGET_OS_WATCH
    import CloudKit
#endif

public class CKHelperFunction: NSObject {
    
    public func getDatabase(privateDB: Bool)->CKDatabase {
        let container = CKContainer(identifier: "iCloud.WMC.DataCruncher")
        return container.publicCloudDatabase
        if privateDB {
            return container.privateCloudDatabase
        } else {
            return container.publicCloudDatabase
        }
    }
    
    public typealias subscriptionFetchCallback = (CKSubscription?, NSError?) -> Void
    
    public func getUniqueSubscriberWithID(privateDB: Bool, subscribeID: String, createSubscribtion: ()->CKSubscription, completionHandler: subscriptionFetchCallback) {
        getUniqueSubscriberWithID(privateDB, subscribeID: subscribeID, createSubscribtion: createSubscribtion, retryCounter: 10, completionHandler: completionHandler)
    }
    
    public func getUniqueSubscriberWithID(privateDB: Bool, subscribeID: String, createSubscribtion: ()->CKSubscription, retryCounter: UInt8, completionHandler: subscriptionFetchCallback) {
        let db = getDatabase(privateDB)
        let callback =  {
            (subscription: CKSubscription?, error: NSError?)->Void in
            if let error = error {
                
                if (error.code == CKErrorCode.UnknownItem.rawValue) {
                    let sub = createSubscribtion()
                    db.saveSubscription(sub, completionHandler: {
                        (_, error: NSError?) -> Void in
                        if let error = error {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(sub, error)
                        }
                    })
                    return
                } else {
                    
                    //Something is wrong
                    //Delete old subscription, start again
                    
                    db.deleteSubscriptionWithID(subscribeID, completionHandler: { (_, _) -> Void in
                        
                        //Start again
                        
                        if (retryCounter > 0) {
                            dispatch_after(NSEC_PER_SEC*UInt64(arc4random_uniform(10)), dispatch_get_main_queue(), { () -> Void in
                                self.getUniqueSubscriberWithID(privateDB, subscribeID: subscribeID, createSubscribtion: createSubscribtion, retryCounter: retryCounter-1, completionHandler: completionHandler)
                            })
                        } else {
                            completionHandler(nil, error)
                        }
                    })
                }
                
            } else {
                //Get subscription
                if let _ = subscription {
                    completionHandler(subscription, error)
                } else {
                    let sub = createSubscribtion()
                    db.saveSubscription(sub, completionHandler: {
                        (_, error: NSError?) -> Void in
                        if let error = error {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(sub, error)
                        }
                    })
                }
            }
        }
        db.fetchSubscriptionWithID(subscribeID, completionHandler: callback)
    }
    
    public typealias recordFetchCallback = (CKRecord?, NSError?) -> Void
    
    @objc public func getUniqueRecordWithID(privateDB: Bool, query: CKQuery, recreateRecord: ()->CKRecord, completionHandler: recordFetchCallback) {
        getUniqueRecordWithID(privateDB, query: query, recreateRecord: recreateRecord, retryCounter: 10, completionHandler: completionHandler)
    }
    
    @objc public func getUniqueRecordWithID(privateDB: Bool, query: CKQuery, recreateRecord: ()->CKRecord, retryCounter: UInt8, completionHandler: recordFetchCallback) {
        let db = getDatabase(privateDB)
        let callback = {
            (records: [CKRecord]?, error: NSError?) -> Void in
            if let error = error {
                //Handle error
                if (retryCounter > 0) {
                    dispatch_after(NSEC_PER_SEC*5, dispatch_get_main_queue(), { () -> Void in
                        self.getUniqueRecordWithID(privateDB, query: query, recreateRecord: recreateRecord, retryCounter: retryCounter-1, completionHandler: completionHandler)
                    })
                } else {
                    completionHandler(nil, error)
                }
            } else {
                if records!.count >= 1 {
                    return completionHandler(records![0], nil)
                } else if records!.count == 0 {
                    let record = recreateRecord()
                    db.saveRecord(record, completionHandler: {
                        (_, error: NSError?)->Void in
                        if let error = error {
                            completionHandler(nil, error)
                        } else {
                            completionHandler(record, nil)
                        }
                    })
                }
            }
        }
        db.performQuery(query, inZoneWithID: nil, completionHandler: callback)
    }
    
    public func resetRecord(privateDB: Bool, record: CKRecord) {
        let database = getDatabase(privateDB)
        //Copy record
        let newRecord = CKRecord(recordType: record.recordType)
        for key in record.allKeys() {
            newRecord[key] = record[key];
        }
        //Delete old record
        let modification = CKModifyRecordsOperation(recordsToSave: [newRecord], recordIDsToDelete: [record.recordID])
        modification.modifyRecordsCompletionBlock = {
            (save: [CKRecord]?, deleteID: [CKRecordID]?, error: NSError?)->Void in
            if let error = error {
                print(error)
            }
        }
        database.addOperation(modification)
    }
    
}