//
//  InterfaceController.swift
//  Wearable Cruncher Extension
//
//  Created by Wai Man Chan on 1/4/16.
//
//

import WatchKit
import Foundation
import CruncherCore

class ValueSummaryController: NSObject {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var valueLabel: WKInterfaceLabel!
    @IBOutlet weak var timeLabel: WKInterfaceLabel!
    func setObj(key: String, _ value: (NSDate, NSData)) {
        do {
            if let dict = try NSJSONSerialization.JSONObjectWithData(value.1, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                titleLabel.setText(key)
                if let obj = dict.allValues.first as? NSObject {
                    valueLabel.setText(obj.description)
                }
                let date = value.0
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.ShortStyle
                formatter.timeStyle = NSDateFormatterStyle.ShortStyle
                timeLabel.setText( formatter.stringFromDate(date) )
            }
        } catch {
            
        }
    }
}

class InterfaceController: WKInterfaceController {
    
    let storageContiner = CacheStorageSpace.commonStorageSpace
    
    @IBOutlet var table: WKInterfaceTable! = nil
    
    var keys: [String] = []
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        renderUI()
    }
    
    func renderUI() {
        keys = storageContiner.allKeys()
        
        // Configure interface objects here.
        table.insertRowsAtIndexes(NSIndexSet.init(indexesInRange: NSMakeRange(0, keys.count)), withRowType: "Summary")
        var counter = 0
        for key in keys {
            let con = table.rowControllerAtIndex(counter) as! ValueSummaryController
            if let record = storageContiner.newestValueForKey(key) {
                con.setObj(key, record)
            }
            counter+=1
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
            dispatch_async(dispatch_get_main_queue()) {
                watchSyncProtocol.sharedProtocol.syncPacket()
            }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func refreshValue(_: AnyObject?) {
        let count = table.numberOfRows
        let range = NSMakeRange(0, count)
        let indexSet = NSIndexSet(indexesInRange: range)
        table.removeRowsAtIndexes(indexSet)
        renderUI()
    }
    
    @IBAction func changeSetting(_: AnyObject?) {
        self.pushControllerWithName("ComplicationSetting", context: nil)
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        return keys[rowIndex]
    }
    
}
