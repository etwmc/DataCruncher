//
//  CCJSONSource.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/18/15.
//
//

import Foundation

public class CCJSONParser: CCProcessor {
    public var parsingCondition: [String: String] = [:]
    
    override public init() {
        super.init()
    }
    
    required public init(coder aDecoder: NSCoder) {
        parsingCondition = aDecoder.decodeObjectForKey("JSONParser-ParsingCondition") as! [String : String]
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(parsingCondition, forKey: "JSONParser-ParsingCondition")
    }
    
    public override func startProcessWithInput(input: [String : NSObject], complete completeBlock: CCProcessorOutputUpdate) {
        let data = input["Data"] as? NSData
        if let _data = data {
            do {
                let object = try NSJSONSerialization.JSONObjectWithData(_data, options: NSJSONReadingOptions.AllowFragments)
                var result: [String: NSObject] = [:]
                (parsingCondition as NSDictionary).enumerateKeysAndObjectsWithOptions(NSEnumerationOptions.Concurrent, usingBlock: { (_key: AnyObject, _value: AnyObject, _) -> Void in
                    if let key = _key as? String, value = _value as? String {
                        result[key] = object.valueForKeyPath(value) as! NSObject?
                    }
                })
                completeBlock(result)
            } catch let error as NSError {
                completeBlock(["Error": error])
            }
            
        }
        
    }
    
}
