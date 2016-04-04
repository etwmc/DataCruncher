//
//  CCNPWeightedSummation.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/15/15.
//
//

import Foundation

public class CCNPWeightedSummation: CCProcessor {
    var _sizeOfInput: Int8 = 0
    public var sizeOfInput: Int8 {
        get { return _sizeOfInput }
        set(newSize) {
            for (var i = newSize-_sizeOfInput; i > 0; i -= 1) {
                weights.append(1.0)
            }
            for (var i = _sizeOfInput-newSize; i > 0; i -= 1) {
                weights.removeLast()
            }
            _sizeOfInput = newSize
        }
    }
    /*override func numberOfInput() -> UInt8 {
    return _sizeOfWeight
    }
    override func numberOfOutput() -> UInt8 {
    return 1
    }*/
    
    override public init() {
        super.init()
    }
    
    required public init(coder aDecoder: NSCoder) {
        weights = aDecoder.decodeObjectForKey("NPWeightedSummation-Weights") as! [Double]
        
        super.init(coder: aDecoder)
        sizeOfInput = Int8(aDecoder.decodeInt32ForKey("NPWeightedSummation-InputSize"))
    }
    
    override public func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeInt32(Int32(_sizeOfInput), forKey: "NPWeightedSummation-InputSize")
        aCoder.encodeObject(weights, forKey: "NPWeightedSummation-Weights")
    }
    
    public var weights: [Double] = []
    override public func startProcessWithInput(input: [String : NSObject], complete completeBlock: CCProcessorOutputUpdate) {
        var counter = Double(0)
        let values = Array(input.values)
        for (var i = 0; i < Int(_sizeOfInput); i += 1) {
            let weight = weights[i]
            if let val = unwrapObject(values[i], NSNumber.self) as? NSNumber {
                counter += val.doubleValue*weight
            }
        }
        completeBlock(["Sum": counter, "Avg": counter/Double(_sizeOfInput)])
    }
}
