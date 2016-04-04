//
//  CCWatchTextComplication.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/19/15.
//
//

#if os(watchOS)
    import ClockKit
#endif

public class CCWatchTextComplication: CCMonitor {
    
    #if os(watchOS)
    public var textProvider: CLKTextProvider?
    #endif
    
    func available()->Bool {
        return true
    }
    
    enum TextDisplayType {
        case StringVal, NumberVal, UnknownVal
        init(obj: NSObject) {
            if (testObject(obj, NSString.self)) {
                self = .StringVal
            } else if (testObject(obj, NSNumber.self)) {
                self = .NumberVal
            } else {
                self = .UnknownVal
            }
        }
        func displayFormat()->String {
            switch self {
            case .NumberVal, .StringVal:
                return "%@"
            default:
                return "N/A"
            }
        }
    }
    
    public override init(monitorName: String) {
        super.init(monitorName: monitorName)
        #if os(watchOS)
            
        #endif
    }
    
    public required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        #if os(watchOS)
            
        #endif
    }
    
    func suffixNumber(number:NSNumber) -> NSString {
        
        var num:Double = number.doubleValue;
        let sign = ((num < 0) ? "-" : "" );
        
        num = fabs(num);
        
        if (num < 1000.0){
            return "\(sign)\(num)";
        }
        
        let exp:Int = Int(log10(num) / log10(1000));
        
        let units:[String] = ["K","M","G","T","P","E"];
        
        let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10;
        
        return "\(sign)\(roundedNum)\(units[exp-1])";
    }
    
    override public func actualProcess() {
        #if os(watchOS)
            super.actualProcess()
        #elseif os(iOS)
            super.actualProcess()
        #endif
    }
    
    public override func displayValue(input: [String : NSObject], state: CCMonitorState) {
        #if os(watchOS)
            let value = input["Value"]!
            let valueType = TextDisplayType(obj: value)
            switch (valueType) {
            case .NumberVal:
                textProvider = CLKSimpleTextProvider(text: suffixNumber(value as! NSNumber) as String)
                break
            case .StringVal:
                textProvider = CLKSimpleTextProvider(text: value.description)
                break
            default:
                break
            }
        #elseif os(iOS)
            
        #endif
    }
    
}
