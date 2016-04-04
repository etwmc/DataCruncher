//
//  ComplicationController.swift
//  Wearable Cruncher Extension
//
//  Created by Wai Man Chan on 1/4/16.
//
//

import ClockKit
import CruncherCore
import WatchConnectivity

enum valueType {
    case singleNumber
    case singleString
    case ratio
    case list
    case image
}

struct value {
    let name: String
    let value: NSObject
    let type: valueType
    
    //If it's a ratio
    let minValue: NSObject?
    let maxValue: NSObject?
}

class ComplicationController: NSObject, CLKComplicationDataSource, WatchSessionDelegate, WatchComplicationDelegate {
    
    func rebuildData() {
        for comp in CLKComplicationServer.sharedInstance().activeComplications! {
            CLKComplicationServer.sharedInstance().reloadTimelineForComplication(comp)
        }
    }
    
    func updateData() {
        for comp in CLKComplicationServer.sharedInstance().activeComplications! {
            CLKComplicationServer.sharedInstance().extendTimelineForComplication(comp)
        }
    }
    func updateBucket(bucketName: String) {
        
    }
    
    let watchSession = WatchSession.defaultSession
    
    func unwrapValue(input: [String: NSObject])->value {
        return value(name: "", value: "", type: valueType.list, minValue: nil, maxValue: nil)
    }
    
    var currentValue: value? = nil
    
    func sessionHasComplicationUpdate(session: WatchSession, info: [String: NSObject]) {
        currentValue = unwrapValue(info)
    }
    
    override init() {
        super.init()
        
        
        for comp in CLKComplicationServer.sharedInstance().activeComplications! {
            CLKComplicationServer.sharedInstance().reloadTimelineForComplication(comp)
        }
        
        
        watchSyncProtocol.sharedProtocol.complicationDelegate = self
    }
    
    func numberFormatter(   number: NSNumber)->String {
        var num:Double = number.doubleValue;
        let sign = ((num < 0) ? "-" : "" );
        
        num = fabs(num);
        
        if (num < 1000.0){
            return "\(sign)\(num)";
        }
        
        let exp:Int = Int(log10(num) / log10(1000));
        
        let units:[String] = ["K","M","G","T","P","E"];
        
        let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10;
        
        return "\(sign)\(roundedNum)\(units[exp-1])";
    }
    
    func timeTextProvider(value: AnyObject, calendarUnit: NSCalendarUnit, outputAsTime: Bool)->CLKTextProvider {
        if let value = value as? String {
            return CLKSimpleTextProvider(text: value)
        } else if let value = value as? NSDate {
            if (outputAsTime) {
                return CLKTimeTextProvider(date: value)
            } else {
                return CLKDateTextProvider(date: value, units: calendarUnit)
            }
        } else if let value = value as? NSNumber {
            return CLKSimpleTextProvider(text: numberFormatter(value))
        } else if let value = value as? [String: NSObject] {
            //Dictioanry mean custom package
        }
        return CLKSimpleTextProvider(text: "Error")
    }
    
    func complicationTemplate(complication: CLKComplication, currentValue: value)->CLKComplicationTemplate? {
        
        let type = currentValue.type
        
        switch complication.family {
            
        case .CircularSmall:
            switch type {
            case .singleNumber, .singleString:
                let complication = CLKComplicationTemplateCircularSmallStackText()
                complication.line1TextProvider = CLKSimpleTextProvider(text: currentValue.name)
                complication.line2TextProvider = timeTextProvider(currentValue.value, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                return complication
            case .ratio:
                if let currentValue = currentValue.value as? NSNumber,
                    let minValue = currentValue as? NSNumber,
                    let maxValue = currentValue as? NSNumber {
                        let complication = CLKComplicationTemplateCircularSmallRingText()
                        complication.fillFraction = (currentValue.floatValue - minValue.floatValue)/(maxValue.floatValue - minValue.floatValue)
                        complication.textProvider = timeTextProvider(currentValue, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                        return complication
                }
            case .image:
                let complication = CLKComplicationTemplateCircularSmallSimpleImage()
                complication.imageProvider = CLKImageProvider(onePieceImage: currentValue.value as! UIImage)
                return complication
            default:
                return nil
            }
            
        case .ModularLarge:
            switch type {
            case .singleNumber, .singleString, .ratio:
                let complication = CLKComplicationTemplateModularLargeTallBody()
                complication.headerTextProvider = timeTextProvider(currentValue.name, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                complication.bodyTextProvider = timeTextProvider(currentValue.value, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                return complication
            case .list:
                let complication = CLKComplicationTemplateModularLargeTable()
                return complication
            default:
                return nil
            }
            
        case .ModularSmall:
            switch type {
            case .singleNumber, .singleString:
                let complication = CLKComplicationTemplateModularSmallStackText()
                complication.line1TextProvider = timeTextProvider(currentValue.name, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                complication.line2TextProvider = timeTextProvider(currentValue.value, calendarUnit: NSCalendarUnit.Calendar, outputAsTime: false)
                return complication
            case .ratio:
                let complication = CLKComplicationTemplateModularSmallRingText()
                return complication
            case .list:
                let complication = CLKComplicationTemplateModularSmallColumnsText()
                return complication
            case .image:
                let complication = CLKComplicationTemplateModularSmallSimpleImage()
                complication.imageProvider = CLKImageProvider(onePieceImage: currentValue.value as! UIImage)
                return complication
            default:
                return nil
            }
            
        case .UtilitarianLarge:
            switch type {
            default:
                return nil
            }
            
        case .UtilitarianSmall:
            switch type {
            default:
                return nil
            }
            
        }
        return nil
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward, .Forward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        if let array = ComplicationSetting.fetchSubscribe() {
            //If there is complication
            if let key = array.first {
                if let dataPts = CacheStorageSpace.commonStorageSpace.allValuesForKey(key) {
                    var date = NSDate()
                    for dataPt in (dataPts as NSDictionary).allKeys {
                        date = date.earlierDate(dataPt as! NSDate)
                    }
                    handler(date)
                    return
                }
            }
        }
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        if let array = ComplicationSetting.fetchSubscribe() {
            //If there is complication
            if let key = array.first {
                if let dataPts = CacheStorageSpace.commonStorageSpace.allValuesForKey(key) {
                    var date = NSDate()
                    for dataPt in (dataPts as NSDictionary).allKeys {
                        date = date.laterDate(dataPt as! NSDate)
                    }
                    handler(date)
                    return
                }
            }
        }
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    var scheduledComplication: [CLKComplication: [CLKComplicationTimelineEntry]] = [:]
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        
        //Nothing available, try to populate
        if let array = ComplicationSetting.fetchSubscribe() {
            //If there is complication
            if let key = array.first {
                if let (date, data) = CacheStorageSpace.commonStorageSpace.newestValueForKey(key) {
                    do {
                        if (date.timeIntervalSinceNow * -1.0 > 5*60) {
                            //The date is old, refresh
                            WCSession.defaultSession().sendMessage(["Complication": key], replyHandler: nil, errorHandler: nil)
                        }
                        if let dict = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: NSObject] {
                            let currentValue = value(name: dict.first!.0, value: dict.first!.1, type: valueType.singleNumber, minValue: 0, maxValue: Double.infinity)
                            if let template = complicationTemplate(complication, currentValue: currentValue) {
                                let entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                                handler(entry)
                            }
                        }
                    
                    } catch {}
                    
                }
            }
        }
        
        
        // Call the handler with the current timeline entry
        let userDefault = NSUserDefaults()
        //Fetch Compilances list
        if let complicationsConf = userDefault.objectForKey("Complications") as? [[String: NSPredicate]] {
            //If there is setting
            //Get compliances index
            let index = CLKComplicationServer.sharedInstance().activeComplications?.indexOf(complication)
            if let index = index  {
                if complicationsConf.count > index {
                    let conf = complicationsConf[index]
                    //Get configuration
                    //TODO: Calculate score, arrange key in ascending order
                    let keys = [conf.keys.first!]
                    //Get lastest compliance
                    var counter = 0
                    for key in keys {
                        if let rawValue = userDefault.objectForKey("LastestObject-\(key)") {
                            let currentValue = value(name: "key"
                                , value: rawValue as! NSObject, type: valueType.singleNumber, minValue: 0, maxValue: Double.infinity)
                            if let template = complicationTemplate(complication, currentValue: currentValue) {
                                let date = NSDate(timeIntervalSinceNow: Double(counter) * 5.0)
                                counter += 1
                                let entry = CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
                                handler(entry)
                            }
                        }
                    }
                }
            }
            return
        }
        if let rawValue = userDefault.objectForKey("Asset") as? NSObject {
            let currentValue = value(name: "Asset"
                , value: rawValue, type: valueType.singleNumber, minValue: 0, maxValue: Double.infinity)
            let template = complicationTemplate(complication, currentValue: currentValue)
            if let template = template {
                handler(CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template))
                return
            }
        }
        
        
        //Placeholder
        //SHould be an animation of hammer
        let imageName: String = "CruncherHammer"
        let cruncherLogo = UIImage(named: imageName)!
        let template = complicationTemplate(complication, currentValue: value(name: "Cruncher", value: cruncherLogo, type: valueType.image, minValue: nil, maxValue: nil))
            handler(CLKComplicationTimelineEntry(date: NSDate(), complicationTemplate: template!))
        
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        if let array = ComplicationSetting.fetchSubscribe() {
            //If there is complication
            if let key = array.first {
                if let dataPts = CacheStorageSpace.commonStorageSpace.allValuesForKey(key) {
                    var results: [CLKComplicationTimelineEntry] = []
                    let pts = (dataPts as [NSDate: NSData]).filter({ (dataPt) -> Bool in
                        return date.compare(dataPt.0) == .OrderedDescending
                    }).sort({ (a: (NSDate, NSData), b: (NSDate, NSData)) -> Bool in
                        return a.0.compare(b.0) == .OrderedDescending
                    }).suffix(limit)
                    for dataPt in pts {
                        do {
                            
                            if let dict = try NSJSONSerialization.JSONObjectWithData(dataPt.1, options: NSJSONReadingOptions.AllowFragments) as? [String: NSObject] {
                                let currentValue = value(name: dict.first!.0, value: dict.first!.1, type: valueType.singleNumber, minValue: 0, maxValue: Double.infinity)
                                if let template = complicationTemplate(complication, currentValue: currentValue) {
                                    let entry = CLKComplicationTimelineEntry(date: dataPt.0, complicationTemplate: template)
                                    results.append(entry)
                                }
                            }
                            
                        } catch {}
                    }
                    handler(results)
                    return
                }
            }
        }
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        if let array = ComplicationSetting.fetchSubscribe() {
            //If there is complication
            if let key = array.first {
                if let dataPts = CacheStorageSpace.commonStorageSpace.allValuesForKey(key) {
                    var results: [CLKComplicationTimelineEntry] = []
                    let pts = (dataPts as [NSDate: NSData]).filter({ (dataPt) -> Bool in
                        return date.compare(dataPt.0) == .OrderedAscending
                    }).sort({ (a: (NSDate, NSData), b: (NSDate, NSData)) -> Bool in
                        return a.0.compare(b.0) == .OrderedAscending
                    }).suffix(limit)
                    for dataPt in pts {
                        do {
                            
                            if let dict = try NSJSONSerialization.JSONObjectWithData(dataPt.1, options: NSJSONReadingOptions.AllowFragments) as? [String: NSObject] {
                                let currentValue = value(name: dict.first!.0, value: dict.first!.1, type: valueType.singleNumber, minValue: 0, maxValue: Double.infinity)
                                if let template = complicationTemplate(complication, currentValue: currentValue) {
                                    let entry = CLKComplicationTimelineEntry(date: dataPt.0, complicationTemplate: template)
                                    results.append(entry)
                                }
                            }
                            
                        } catch {}
                    }
                    handler(results)
                    return
                }
            }
        }
        handler(nil)
    }
    
    func requestedUpdateDidBegin() {
        
    }
    
    func requestedUpdateBudgetExhausted() {
        
    }
    
    // MARK: - Update Scheduling
    
    let timeValue = 5.0
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(NSDate(timeIntervalSinceNow: timeValue*60))
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        let imageName: String = "CruncherHammer"
        let cruncherLogo = UIImage(named: imageName)!
        let template = complicationTemplate(complication, currentValue: value(name: "Cruncher", value: cruncherLogo, type: valueType.image, minValue: nil, maxValue: nil))
        handler(template)
    }
    
}
