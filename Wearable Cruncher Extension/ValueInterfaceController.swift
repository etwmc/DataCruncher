//
//  ValueInterfaceController.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/19/16.
//
//

import WatchKit
import Foundation

import CruncherCore


class ValueInterfaceController: WKInterfaceController {
    
    @IBOutlet var imageView: WKInterfaceImage! = nil
    @IBOutlet var toggleButton: WKInterfaceButton! = nil
    
    @IBOutlet var valueLabel: WKInterfaceLabel! = nil
    
    var status = false
    
    var bucketName: String! = nil
    
    let storage = CacheStorageSpace.commonStorageSpace
    
    //Model
    func isSubscribing()->Bool {
        return status
    }
    func toggleSubscribeState() {
        if (status) {
            ComplicationSetting.removeSubscribe(bucketName)
        } else {
            ComplicationSetting.addSubscribe(bucketName)
        }
        status = !status
    }
    
    //Controller Constant
    func subscribeButtonString()->String {
        if isSubscribing() { return "Unsubscribe" }
        else { return "Subscribe" }
    }
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        let title: String
        //Test
        title = context as! String
        self.setTitle(title)
        bucketName = title
        
        //Set (image)+value
        
        //Set button
        status = ComplicationSetting.isSubscribe(bucketName)
        let buttonString = subscribeButtonString()
        toggleButton.setTitle(buttonString)
        
        //Characteristic
        
        //Values
        if let value = CacheStorageSpace.commonStorageSpace.newestValueForKey(bucketName) {
            do {
                if let dict = try NSJSONSerialization.JSONObjectWithData(value.1, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                    if let obj = dict.allValues.first as? NSObject {
                        valueLabel.setText(obj.description)
                    }
                }
            } catch {
                
            }
        }
    }
    
    @IBAction func toggleMonitor(sender: WKInterfaceButton) {
        toggleSubscribeState()
        
        let buttonString = subscribeButtonString()
        toggleButton.setTitle(buttonString)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
