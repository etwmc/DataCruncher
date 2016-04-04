//
//  CruncherCoreTests.swift
//  CruncherCoreTests
//
//  Created by Wai Man Chan on 1/9/16.
//
//

import XCTest
import CruncherCore

class CruncherCoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testContainer() {
        let container = CCProcessorContainer()
        
        let networkSource = CCNetworkSource()
        networkSource.url = NSURL(string: "http://apple.com")
        
        container.allProcessors = [networkSource]
        var containerData = NSKeyedArchiver.archivedDataWithRootObject(container)
        var decodedContainer = NSKeyedUnarchiver.unarchiveObjectWithData(containerData)!
        
        let restoredNetworkSource = decodedContainer.allProcessors[0] as! CCNetworkSource
        XCTAssert(networkSource.url.isEqual(restoredNetworkSource.url))
    }
    
    func testNetworkSourceContain() {
        let networkSource = CCNetworkSource()
        networkSource.url = NSURL(string: "http://apple.com")
        var containerData = NSKeyedArchiver.archivedDataWithRootObject(networkSource)
        var restoredNetworkSource = NSKeyedUnarchiver.unarchiveObjectWithData(containerData)!
        XCTAssert(networkSource.url.isEqual(restoredNetworkSource.url))
    }
    
    func testNumberParserRecoery() {
        let numberParser = CCNumberConverter()
        numberParser.startProcessWithInput([
            "Fail": "--",
            "Success": "1234.5678"
            ], complete: { (dict: [String : NSObject]) -> Void in
                XCTAssert(dict["Fail"] as! NSNumber == 0)
                XCTAssert(dict["Success"] as! NSNumber == 1234.5678)
        })
    }
    
}
