//
//  GraphView.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 1/25/16.
//
//

#if os(iOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#endif
import CruncherCore

class GraphView: UIScrollView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}

class GraphInternalView: UIView {
    let bucket: CCStorageBucket? = nil
    var startTime: NSDate? = nil
    var endTime: NSDate? = nil
    
}