//
//  CCMonitor.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/20/15.
//
//

import Foundation

public enum CCMonitorState: UInt8 {
    case Catastrophic = 0
    case Major = 1
    case Emergency = 2
    case Minor = 3
    case Normal = 4
}

public class CCMonitorPredicate {
    var catastrophicPredicator, majorPredicator, emergencyPredicator, minorPredicator, normalPredicator: NSPredicate?
    var catastrophicString = "", majorString = "", emergencyString = "", minorString = "", normalString = ""
    public var catastrophicCondition: String {
        get { return catastrophicString }
        set(s) {
            catastrophicString = s
            catastrophicPredicator = NSPredicate(format: "%@", argumentArray: [s])
        }
    }
    public var majorCondition: String {
        get { return majorString }
        set(s) {
            majorString = s
            majorPredicator = NSPredicate(format: "%@", argumentArray: [s])
        }
    }
    public var emergencyCondition: String {
        get { return emergencyString }
        set(s) {
            emergencyString = s
            emergencyPredicator = NSPredicate(format: "%@", argumentArray: [s])
        }
    }
    public var minorCondition: String {
        get { return minorString }
        set(s) {
            minorString = s
            minorPredicator = NSPredicate(format: "%@", argumentArray: [s])
        }
    }
    public var normalCondition: String {
        get { return normalString }
        set(s) {
            normalString = s
            normalPredicator = NSPredicate(format: "%@", argumentArray: [s])
        }
    }
    func triggerMonitorState(input: [ [String: NSObject] ])->CCMonitorState {
        return .Normal
    }
}

public class CCMonitor: CCProcessor {
    var sampleData: [ [String : NSObject] ] = []
    var predicate: CCMonitorPredicate = CCMonitorPredicate()
    var windowSize: Int = 1
    let storage = CCKeyValueStorage.sharedStorage()
    var storageBucket: CCStorageBucket!
    let monitorName: String
    
    func readInRecord() {
        if let bucket = storage.fetchBucket(monitorName, withHistoricalMode: CCStorageHistoricalMode_Linear) {
            storageBucket = bucket
        } else {
            storageBucket = storage.createStorageBucket(monitorName, withHistoricalMode: CCStorageHistoricalMode_Linear)
        }
        //Read in records
        
    }
    
    public init(monitorName: String) {
        self.monitorName = monitorName
        
        super.init()
        
        readInRecord()
        
        selfUpdateInterval = 0
    }
    
    required public init(coder aDecoder: NSCoder) {
        windowSize = aDecoder.decodeIntegerForKey("Monitor-WindowSize")
        monitorName = aDecoder.decodeObjectForKey("Monitor-MonitorName") as! String
        
        super.init(coder: aDecoder)
        
        readInRecord()
    }
    
    public override func encodeWithCoder(encoder: NSCoder) {
        super.encodeWithCoder(encoder)
        encoder.encodeInteger(windowSize, forKey: "Monitor-WindowSize")
        encoder.encodeObject(monitorName, forKey: "Monitor-MonitorName")
    }
    
    public override func startProcessWithInput(input: [String : NSObject], complete completeBlock: CCProcessorOutputUpdate) {
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(input, options: NSJSONWritingOptions.init(rawValue: 0))
            #if !os(watchOS)
                _ = storageBucket.insertData(data)
            #endif
        } catch let error as NSError {
            print(error)
        }
        
        sampleData.insert(input, atIndex: 0)
        if sampleData.count > windowSize {
            sampleData = Array(sampleData.dropLast(sampleData.count-windowSize))
        }
        var result: [String: NSObject] = [:]
        let state = predicate.triggerMonitorState(sampleData)
        switch state {
        case .Catastrophic:
            result["Catastrophic"] = result
        case .Major:
            result["Major"] = result
        case .Emergency:
            result["Emergency"] = result
        case .Minor:
            result["Minor"] = result
        case .Normal:
            result["Normal"] = result
        }
        displayValue(input, state: state)
        completeBlock(result)
    }
    
    public func displayValue(input: [String : NSObject], state: CCMonitorState) {}
    
    public override func outputTransformation(inputDict: [NSObject : AnyObject]) -> [NSObject : AnyObject] {
        let values = inputDict.values
        if values.count > 0 {
            return values.first as! [NSObject: AnyObject]
        }
        else { return [:] }
    }
    
    deinit {
        //Save sample data
        storage.saveStorage()
    }
}
