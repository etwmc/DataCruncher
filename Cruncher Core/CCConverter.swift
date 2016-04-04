//
//  CCConverter.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/15/15.
//
//

import Foundation

extension Dictionary {
    init<S: SequenceType where S.Generator.Element == Element>
        (_ seq: S) {
            self.init()
            for (k,v) in seq {
                self[k] = v
            }
    }
    
    func mapValues<T>(transform: Value->T) -> Dictionary<Key,T> {
        return Dictionary<Key,T>(zip(self.keys, self.values.map(transform)))
    }
    
}

public class CCNumberConverter: CCProcessor {
    static let formatter = NSNumberFormatter()
    override public func numberOfInput() -> UInt8 {
        return 1
    }
    override public func numberOfOutput() -> UInt8 {
        return 1
    }
    
    override public init() {
        super.init()
    }
    
    required public init(coder aDecoder: NSCoder) {
        //        parsingCondition = aDecoder.decodeObjectForKey("NumberConverter-ParsingCondition")!
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        //        aCoder.encodeObject(parsingCondition, forKey: "NumberConverter-ParsingCondition")
    }
    
    override public func startProcessWithInput(input: [String : NSObject], complete completeBlock: CCProcessorOutputUpdate) {
        
        var result = input.mapValues({ (val: NSObject) -> NSObject in
            
            if let oldValue = unwrapObject(val, NSString.self) as? String {
                let value = CCNumberConverter.formatter.numberFromString(oldValue)
                if let value = value {
                    return value
                }
            } else if let oldValue = unwrapObject(val, NSNumber.self) as? NSNumber {
                return oldValue
            }
            
            print("CCNumberConverter: The value to convert is no good: ", val.description, unwrapObject(val, NSString.self) as? String, unwrapObject(val, NSNumber.self) as? NSNumber)
            return NSNull()
            
        })
        
        for (key, value) in result {
            if value.isKindOfClass(NSNull.self) {
                result.removeValueForKey(key)
            }
        }
        
        completeBlock(result)
    }
}

public class CCFormatStringConverter: CCProcessor {
    var _numberOfInput: UInt8 = 0;
    override public func numberOfInput() -> UInt8 {
        return _numberOfInput
    }
    var format = ""
    override public func numberOfOutput() -> UInt8 {
        return 1
    }
    
    required public init(coder aDecoder: NSCoder) {
        format = aDecoder.decodeObjectForKey("FormatStringConverter-Format") as! String
        _numberOfInput = UInt8(aDecoder.decodeInt32ForKey("FormatStringConverter-InputSize"))
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(format, forKey: "FormatStringConverter-Format")
        aCoder.encodeInt32(Int32(_numberOfInput), forKey: "FormatStringConverter-InputSize")
    }
    
}