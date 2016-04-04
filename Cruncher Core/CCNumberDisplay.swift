//
//  CCNumberDisplay.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/27/15.
//
//

import Foundation
import CoreGraphics

public struct CCDisplayScope {
    public let startTime: NSDate
    public let endTime: NSDate
    public init(beginTime: NSDate, endTime: NSDate) {
        self.startTime = beginTime
        self.endTime = endTime
    }
    public enum CCDisplayTimeFrame: NSInteger {
        case Hour = 3600
        case Day = 86400
        case Week = 604800
        case Month = 2592000
        case Year = 31536000
        func timeFromNow()->NSDate {
            return NSDate(timeIntervalSinceNow: Double(-1*self.rawValue))
        }
    }
    public init(timeFrame: CCDisplayTimeFrame) {
        endTime = NSDate()
        startTime = timeFrame.timeFromNow()
    }
    public func linearTransform(deltaT: Double)->CCDisplayScope {
        return CCDisplayScope(beginTime: startTime.dateByAddingTimeInterval(deltaT), endTime: endTime.dateByAddingTimeInterval(deltaT))
    }
    public func linearScale(scale: Double)->CCDisplayScope {
        let middleTime = NSDate(timeIntervalSinceReferenceDate: (startTime.timeIntervalSinceReferenceDate+endTime.timeIntervalSinceReferenceDate)/2)
        let timeLength = (endTime.timeIntervalSinceReferenceDate-startTime.timeIntervalSinceReferenceDate)/2*scale
        return CCDisplayScope(beginTime: middleTime.dateByAddingTimeInterval(-1*timeLength), endTime: middleTime.dateByAddingTimeInterval(timeLength))
    }
}

public class CCNumberDisplayModel: NSObject {
    
    let valueBucket: CCStorageBucket
    
    public init?(bucketName: String) {
        let storage = CCKeyValueStorage.sharedStorage()
        if let bucket = storage.fetchBucket(bucketName, withHistoricalMode: CCStorageHistoricalMode_Linear) {
            valueBucket = bucket
            super.init()
        } else {
            valueBucket = CCStorageBucket()
            super.init()
            return nil
        }
    }
    
    public func valueMapping(scope: CCDisplayScope, frameSize: CGSize)->(min: Double, points:[CGPoint]) {
        var array: [CGPoint] = []
        //Fetch data points
        let predicate = NSPredicate(format: "(insertDate >= %@) && (insertDate <= %@)", argumentArray: [scope.startTime, scope.endTime])
        let values = valueBucket.dataFilteredWithPredicate(predicate)
        
        
        return (0, array)
    }
    
}
