//
//  CCConstant.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/20/15.
//
//

public class CCConstant <T: NSObject>: CCProcessor {
    internal var value: T
    internal let defaultValue: T
    internal init(defaultValue: T) {
        self.value = defaultValue
        self.defaultValue = defaultValue
        super.init()
        selfUpdateInterval = NSTimeInterval.infinity
    }
    internal init(defaultValue: T, value: T) {
        self.value = value
        self.defaultValue = defaultValue
        super.init()
        selfUpdateInterval = NSTimeInterval.infinity
    }
    public override func startProcessWithInput(input: [String : NSObject]?, complete completeBlock: CCProcessorOutputUpdate) {
        completeBlock(["Constant": value])
    }
}

public class CCNumberConstant: CCConstant<NSNumber> {
    init() { super.init(defaultValue: 0.0) }
    init(number: Double) { super.init(defaultValue: 0.0, value: number) }
    var Number:NSNumber {
        get { return self.value }
        set(t) { self.value = t }
    }
    internal let configureKey: [String] = ["Number"]
}

public class CCStringConstant: CCConstant<NSString> {
    init() { super.init(defaultValue: "Placeholder") }
    init(text: String) { super.init(defaultValue: "Placeholder", value: text) }
    var Text:String {
        get { return self.value as String }
        set(t) { self.value = t }
    }
    internal static let configureKey: [String] = ["Text"]
}

public class CCDataConstant: CCConstant<NSData> {
    private var filePath: String?
    init() {
        filePath = nil
        super.init(defaultValue: NSData())
    }
    init(path: String) {
        filePath = path
        let _data = NSData(contentsOfFile: path)
        if let data = _data {
            super.init(defaultValue: NSData(), value: data)
        } else {
            super.init(defaultValue: NSData())
        }
    }
    var FilePath:String? {
        get { return filePath }
        set(t) {
            self.filePath = t
            if let filePath = filePath {
                let _data = NSData(contentsOfFile: filePath)
                if let data = _data {
                    value = data
                } else {
                    value = NSData()
                }
            }
        }
    }
    internal static let configureKey: [String] = ["FilePath"]
}