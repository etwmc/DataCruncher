//
//  DeviceConsolidate.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/26/15.
//
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif
import CloudKit

#if os(OSX)
    extension String {
        
        static func macSerialNumber() -> String {
            
            // Get the platform expert
            let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
            
            // Get the serial number as a CFString ( actually as Unmanaged<AnyObject>! )
            let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey, kCFAllocatorDefault, 0);
            
            // Release the platform expert (we're responsible)
            IOObjectRelease(platformExpert);
            
            // Take the unretained value of the unmanaged-any-object
            // (so we're not responsible for releasing it)
            // and pass it back as a String or, if it fails, an empty string
            return (serialNumberAsCFString.takeUnretainedValue() as? String) ?? ""
            
        }
        
    }
#endif

public class DeviceConsolidate: NSObject {
    let privateDB: CKDatabase
    var deviceList: [CKRecord] = []
    
    public static let shareConsolidate = DeviceConsolidate()
    
    private override init() {
        let container = CKContainer(identifier: "iCloud.WMC.DataCruncher")
        privateDB = container.publicCloudDatabase
        
        super.init()
        
        privateDB.performQuery(CKQuery(recordType: "Device", predicate: NSPredicate(value: true)), inZoneWithID: nil) { (list: [CKRecord]?, error: NSError?) -> Void in
            if let error = error {
                //Display Error
                print(error)
            } else if let list = list {
                self.deviceList = list
            }
        }
        
        registerDevice()
        
        CKHelperFunction().getUniqueSubscriberWithID(true, subscribeID: "DeviceChange", createSubscribtion: { () -> CKSubscription in
            let deviceChangeSubscription = CKSubscription(recordType: "Device", predicate: NSPredicate(value: true), subscriptionID: "DeviceChange", options: CKSubscriptionOptions.FiresOnRecordCreation.union(CKSubscriptionOptions.FiresOnRecordDeletion))
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertBody = ""
            notificationInfo.category = "Device_Change"
            notificationInfo.shouldSendContentAvailable = true
            deviceChangeSubscription.notificationInfo = notificationInfo
            return deviceChangeSubscription
            }
            , completionHandler: { (subscription: CKSubscription?, error: NSError?) -> Void in
        })
        
    }
    
    private func deviceIdentifier()->NSString {
        #if os(iOS)
            return UIDevice.currentDevice().identifierForVendor!.UUIDString
        #elseif os(OSX)
            return String.macSerialNumber()
        #endif
    }
    
    private func deviceName()->String? {
        #if os(iOS)
            return UIDevice.currentDevice().name
        #elseif os(OSX)
            return NSHost.currentHost().name
        #endif
    }
    
    func registerDevice() {
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(format: "UUID == %@", argumentArray: [deviceIdentifier()]))
        privateDB.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error: NSError?) -> Void in
            if let error = error {
                print("Query", error)
                return
            }
            if (records?.count == 0) {
                let deviceRecord = CKRecord(recordType: "Device")
                deviceRecord.setObject(self.deviceIdentifier(), forKey: "UUID")
                deviceRecord.setObject(self.deviceName(), forKey: "DeviceName")
                self.privateDB.saveRecord(deviceRecord, completionHandler: { (_, error: NSError?) -> Void in
                    print("Write", error)
                })
            } else {
                print("Query ID", records![0].recordID)
            }
        }
    }
    
    public func devicesList()->[CKRecord] {
        return deviceList
    }
    
    public func handleNotification(userInfo: [NSObject : AnyObject]) {
        let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        let recordID = notification.recordID
        switch notification.queryNotificationReason {
        case .RecordCreated:
            privateDB.fetchRecordWithID(recordID!, completionHandler: { (record: CKRecord?, error: NSError?) -> Void in
                if error == nil {
                    self.deviceList.append(record!)
                }
            })
            break
        case .RecordDeleted:
            deviceList = deviceList.filter({ (record: CKRecord) -> Bool in
                return !record.recordID.isEqual(recordID)
            })
            break
        default:
            break
        }
    }
    
}
