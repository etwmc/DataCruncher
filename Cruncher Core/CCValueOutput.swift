//
//  CCValueOutput.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/19/15.
//
//

import Foundation

public class CCValueOutput: CCMonitor {
    public var valueUpdate: CCProcessorOutputUpdate? = nil
    public override func displayValue(input: [String : NSObject], state: CCMonitorState) {
        valueUpdate?(input)
    }
}
