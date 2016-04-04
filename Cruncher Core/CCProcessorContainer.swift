//
//  CCProcessorContainer.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/22/15.
//
//

import Foundation
#if !os(watchOS)
    import CloudKit
#endif

public class CCProcessorContainer: NSObject, NSCoding {
    public var containerName = "New Container"
    public var allProcessors: [CCProcessor]
    public var outputProcessors: [CCProcessor]
    
    class CCProcessorRelationship: NSObject, NSCoding {
        internal let srcProcessorUUID: NSUUID
        internal let dstProcessorUUID: NSUUID
        internal let srcProcessorPort: String
        internal let dstProcessorPort: String
        init(srcProcessor: CCProcessor, srcPort: String,
            dstProcessor: CCProcessor, dstPort: String) {
                srcProcessorUUID = srcProcessor.processorUUID
                dstProcessorUUID = dstProcessor.processorUUID
                srcProcessorPort = srcPort
                dstProcessorPort = dstPort
        }
        @objc required init?(coder aDecoder: NSCoder) {
            srcProcessorUUID = NSUUID(UUIDString: aDecoder.decodeObjectForKey("Src UUID") as! String)!
            dstProcessorUUID = NSUUID(UUIDString: aDecoder.decodeObjectForKey("Dst UUID") as! String)!
            srcProcessorPort = aDecoder.decodeObjectForKey("Src Port") as! String
            dstProcessorPort = aDecoder.decodeObjectForKey("Dst Port") as! String
        }
        @objc func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(srcProcessorUUID.UUIDString, forKey: "Src UUID")
            aCoder.encodeObject(dstProcessorUUID.UUIDString, forKey: "Dst UUID")
            aCoder.encodeObject(srcProcessorPort, forKey: "Src Port")
            aCoder.encodeObject(dstProcessorPort, forKey: "Dst Port")
        }
    }
    
    override public init() {
        allProcessors = []
        outputProcessors = []
    }
    
    required public init?(coder aDecoder: NSCoder) {
        if let name = aDecoder.decodeObjectForKey("Name") as? String {
            containerName = name
        }
        
        //Read in processors
        allProcessors = aDecoder.decodeObjectForKey("Processors") as! [CCProcessor]
        var processorDict: [NSUUID: CCProcessor] = [:]
        (allProcessors as NSArray).enumerateObjectsUsingBlock({ (proc, _, _) -> Void in
            let processor = proc as! CCProcessor
            processorDict[processor.processorUUID] = processor
        })
        
        //Read in processors respondible for output
        if let outputUUID = aDecoder.decodeObjectForKey("Output") as? Array<NSUUID> {
            outputProcessors = allProcessors.filter({ (processor: CCProcessor) -> Bool in
                return outputUUID.contains(processor.processorUUID)
            })
        } else {
            outputProcessors = []
        }
        
        //Setup all the relationship
        if let relationships = aDecoder.decodeObjectForKey("Relationship") as? [CCProcessorRelationship] {
            (relationships as NSArray).enumerateObjectsUsingBlock({ (relationship, _, _) -> Void in
                let rels = relationship as! CCProcessorRelationship
                let srcProc = processorDict[rels.srcProcessorUUID]
                let dstProc = processorDict[rels.dstProcessorUUID]
                if let srcProc = srcProc, let dstProc = dstProc {
                    dstProc.connectInput(rels.dstProcessorPort, toProcessor: srcProc, forOutput: rels.srcProcessorPort)
                }
            })
        }
        
        super.init()
        
    }
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(containerName, forKey: "Name")
        
        //Write all processors
        aCoder.encodeObject(allProcessors, forKey: "Processors")
        
        //Write all output UUID
        let outputUUID = outputProcessors.map { (processor: CCProcessor) -> NSUUID in
            return processor.processorUUID
        }
        aCoder.encodeObject(outputUUID, forKey: "Output")
        
        //Setup relationship
        let relationshipArray = allProcessors.map({ (processor: CCProcessor) -> [CCProcessorRelationship] in
            return processor.mapping().map({ (input:(String, CCOutputPort)) -> CCProcessorRelationship in
                return CCProcessorRelationship(srcProcessor: input.1.sourceProcessor, srcPort: input.1.outputName, dstProcessor: processor, dstPort: input.0)
            })
        }).reduce([], combine: +)
        aCoder.encodeObject(relationshipArray, forKey: "Relationship")
    }
    
    #if !os(watchOS)
    public func convertToCKRecord()->CKRecord {
        let record = CKRecord(recordType: "Container")
        record["Name"] = containerName
        
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let addr = (path as NSString).stringByAppendingPathComponent("TempContainer")
        NSKeyedArchiver.archiveRootObject(self, toFile: addr)
        
        record["ContainerData"] = CKAsset(fileURL: NSURL(fileURLWithPath: addr))
        return record
    }
    #endif
    
}

@objc public protocol CCProcessorContainerManagerDelegate {
    func containerAdded(container: CCProcessorContainer);
    func containerUpdated(container: CCProcessorContainer);
    func containerRemoved(container: CCProcessorContainer);
}

#if !os(watchOS)

public class CCProcessorContainerManager: NSObject {
    public static let sharedManager = CCProcessorContainerManager()
    
    public var delegate: CCProcessorContainerManagerDelegate?
    
    var _containers: [CCProcessorContainer] = []
    public var containers: [CCProcessorContainer] {
        get {
            waitForContainers()
            return _containers
        }
    }
    
    let containerSem = dispatch_semaphore_create(0)
    
    func waitForContainers() {
        dispatch_semaphore_wait(containerSem, DISPATCH_TIME_FOREVER)
        dispatch_semaphore_signal(containerSem)
    }
    
    func fetchAllContainer() {
        let query = CKQuery(recordType: "Container", predicate: NSPredicate(value: true))
        let database = CKHelperFunction().getDatabase(true)
        database.performQuery(query, inZoneWithID: nil) { (records: [CKRecord]?, error: NSError?) -> Void in
            if let error = error {
                print(error)
            } else {
                let records = records!
                self._containers = records.map({ (record: CKRecord) -> CCProcessorContainer in
                    let dataURL = (record.valueForKey("ContainerData") as! CKAsset).fileURL
                    return NSKeyedUnarchiver.unarchiveObjectWithFile(dataURL.path!) as! CCProcessorContainer
                })
                self._containers.sortInPlace({ (a: CCProcessorContainer, b: CCProcessorContainer) -> Bool in
                    return (a.containerName.compare(b.containerName) != NSComparisonResult.OrderedDescending)
                })
            }
            dispatch_semaphore_signal(self.containerSem)
        }
    }
    
    func containerSubscription() {
        let subID = "Container-Subscribe"
        CKHelperFunction().getUniqueSubscriberWithID(true, subscribeID: subID, createSubscribtion: { () -> CKSubscription in
            return CKSubscription(recordType: "Container", predicate: NSPredicate(value: true), subscriptionID: subID, options: CKSubscriptionOptions.FiresOnRecordCreation.union(CKSubscriptionOptions.FiresOnRecordDeletion).union(CKSubscriptionOptions.FiresOnRecordUpdate))
            }, completionHandler: { (sub: CKSubscription?, error: NSError?) -> Void in
                
        })
    }
    
    func addContainer() {
        let container = CCProcessorContainer()
        CKHelperFunction().getDatabase(true).saveRecord(container.convertToCKRecord()) { (record: CKRecord?, error: NSError?) -> Void in
            self._containers.insert(container, atIndex: 0)
            self.delegate?.containerAdded(container)
        }
    }
    
    func removeContainer(index: Int) {
        let container = _containers[index]
        _containers.removeAtIndex(index)
        let recordID = container.convertToCKRecord().recordID
        CKHelperFunction().getDatabase(true).deleteRecordWithID(recordID) { (record: CKRecordID?, error: NSError?) -> Void in
            if let record = record {
                self.delegate?.containerRemoved(container)
            } else {
                //Recover
                self._containers.insert(container, atIndex: index)
            }
        }
    }
    
    func updateContainer(index: Int, container: CCProcessorContainer) {
        CKHelperFunction().getDatabase(true).saveRecord(container.convertToCKRecord()) { (_, error: NSError?) -> Void in
            if let error = error {
                
            } else {
                self.delegate?.containerUpdated(container)
            }
        }
    }
    
    public func containerManagerNotification(userInfo: [NSObject : AnyObject]) {
        let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        if let recordID = notification.recordID {
            CKHelperFunction().getDatabase(true).fetchRecordWithID(recordID) { (record: CKRecord?, error: NSError?) -> Void in
                switch notification.queryNotificationReason {
                case .RecordCreated:
                    
                    break;
                default:
                    break;
                }
            }
        }
    }
    
    override init() {
        super.init()
        
        containerSubscription()
        
        fetchAllContainer()
    }
}

#endif