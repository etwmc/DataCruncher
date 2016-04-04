//
//  BCItem.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/25/15.
//
//

import Cocoa
import CruncherCore

class BCItem: NSObject, CCProcessorDelegate {
    
    static let dateFormatter = NSDateFormatter()
    
    let container: CCProcessorContainer
    var label: NSMenuItem?
    var lastUpdateTime: NSDate?
    init(container: CCProcessorContainer) {
        BCItem.dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        BCItem.dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        self.container = container
        
        super.init()
        _ = container.outputProcessors.map({ (proc: CCProcessor) -> Void in
            proc.delegate = self
        })
    }
    
    @objc func processorHasFinishUpdate(processor: CCProcessor) {
        lastUpdateTime = NSDate()
        let updateLabel = label?.submenu?.itemAtIndex(0)!
        updateLabel?.title = "Last Update: "+BCItem.dateFormatter.stringFromDate(lastUpdateTime!)
    }
}
