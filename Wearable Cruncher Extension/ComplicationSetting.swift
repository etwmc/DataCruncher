//
//  ComplicationSetting.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 3/27/16.
//
//

import Foundation
import CruncherCore

class ComplicationSetting {
    static func addSubscribe(bucketName: String) {
        var array = NSUserDefaults.standardUserDefaults().arrayForKey("Complication") as? [String]
        if (array == nil) { array = [] }
        array?.append(bucketName)
        NSUserDefaults.standardUserDefaults().setObject(array, forKey: "Complication")
        NSUserDefaults.standardUserDefaults().synchronize()
        WatchSession.defaultSession.subscribeKeys(array!)
    }
    static func fetchSubscribe()->[String]? {
        let array = NSUserDefaults.standardUserDefaults().arrayForKey("Complication") as? [String]
        return array
    }
    static func removeSubscribe(bucketName: String) {
        var array = NSUserDefaults.standardUserDefaults().arrayForKey("Complication") as? [String]
        if let index = array?.indexOf(bucketName) {
            array?.removeAtIndex(index)
            NSUserDefaults.standardUserDefaults().setObject(array, forKey: "Complication")
            NSUserDefaults.standardUserDefaults().synchronize()
            WatchSession.defaultSession.subscribeKeys(array!)
        }
    }
    static func isSubscribe(bucketName: String)->Bool {
        let array = NSUserDefaults.standardUserDefaults().arrayForKey("Complication") as? [String]
        return ( array?.indexOf(bucketName) != nil )
    }
}
