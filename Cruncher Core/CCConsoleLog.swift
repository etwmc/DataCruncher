//
//  CCConsoleLog.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/18/15.
//
//

import Foundation

public class CCConsoleLog: CCMonitor {
    public override func displayValue(input: [String : NSObject], state: CCMonitorState) {
        print(NSDate(), input)
    }
}
