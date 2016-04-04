//
//  CCHTMLParser.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/16/15.
//
//

import Foundation

import Kanna

public class CCHTMLNode: CCProcessorValue {
    public let tagName: String
    public let attributeDict: [String: String]
    public let value: String
    override init() {
        tagName = ""
        attributeDict = [:]
        value = ""
        super.init()
        self.defaultValueKey = "value"
    }
    init(tagName: String, attributeDict: [String: String], value: String, parentNode: CCHTMLNode?) {
        self.tagName = tagName
        self.attributeDict = attributeDict
        self.value = value
        super.init()
        self.defaultValueKey = "value"
    }
}

public class CCHTMLParser: CCProcessor {
    public var parsingCondition: [String: String] = [:]
    
    override public init() {
        super.init()
    }
    
    required public init(coder aDecoder: NSCoder) {
        parsingCondition = aDecoder.decodeObjectForKey("HTMLParser-ParsingCondition") as! [String : String]
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(parsingCondition, forKey: "HTMLParser-ParsingCondition")
    }
    
    public override func startProcessWithInput(input: [String : NSObject], complete completeBlock: CCProcessorOutputUpdate) {
        let data = input["Data"] as? NSData
        // Swift-HTML-Parser
        if let _data = data {
            let _doc: HTMLDocument?
            // New: Kanna
            _doc = Kanna.HTML(html: _data, encoding: NSUTF8StringEncoding)
            if let doc = _doc {
                var result: [String: [CCHTMLNode]] = [:]
                (parsingCondition as NSDictionary).enumerateKeysAndObjectsWithOptions(NSEnumerationOptions.Concurrent, usingBlock: { (_key: AnyObject, _value: AnyObject, _) -> Void in
                    if let key = _key as? String, value = _value as? String {
                        let set = doc.xpath(value)
                        let nodes = set.map({ (element: XMLElement) -> CCHTMLNode in
                            return CCHTMLNode(tagName: element.tagName!, attributeDict: [:], value: element.innerHTML!, parentNode: nil)
                        })
                        result[key] = nodes
                    }
                })
                completeBlock(result)
            }
            
        }
        
    }
    
}
