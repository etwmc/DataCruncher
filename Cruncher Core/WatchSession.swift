//
//  WatchSession.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/24/15.
//
//

import WatchConnectivity
#if os(watchOS)
    import ClockKit
#endif

#if os(watchOS)
@objc public protocol WatchSessionDelegate {
    optional func sessionHasComplicationUpdate(info: [String: NSObject])
}
#endif

func platformSensitiveFunction<T>(functionDescibe: String,
                               inout osxCode: T?,
                               inout iOSCode: T?,
                               inout watchOSCode: T?,
                               inout tvOSCode: T?)->T? {
    #if (OSX)
        return osxCode
    #elseif (iOS)
        return iOSCode
    #elseif (watchOS)
        return watchOSCode
    #elseif (tvOS)
        return tvOSCode
    #else
        print("Platform is not defined \(functionDescibe)")
        return nil
    #endif
}

public class WatchSession: NSObject, WCSessionDelegate {
    
    public static let defaultSession = WatchSession()
    
    public var monitor: ProtocolCipher? = nil
    
    var session: WCSession?
    
    var context: [String: AnyObject] = [:]
    
    let seamphore = dispatch_semaphore_create(0)
    
    public override init() {
        super.init()
        self.sessionInit()
    }
    
    internal func sessionInit() {
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            context = WCSession.defaultSession().applicationContext
        } else { session = nil }
        session?.delegate = self
        session?.activateSession()
    }
    
    public func canSendMessage()->Bool {
        if #available(iOS 9.3, *) {
            if (session?.activationState != .Activated) {
                session?.activateSession()
            }
            return (session != nil) && (session?.activationState == .Activated)
        } else {
            // Fallback on earlier versions
            return (session != nil)
        }
    }
    
    public func sendUserInfo(dict: [String: AnyObject]) {
        debugPrint("Send User Info")
        if (canSendMessage()) {
            #if os(iOS)
                if (session != nil && session!.reachable) {
                    session?.sendMessage(dict, replyHandler: nil, errorHandler: { (error: NSError) in
                        NSLog("Error: %@", error)
                    })
                } else {
                    session?.transferUserInfo(dict)
                }
            #endif
            #if os(watchOS)
                session?.sendMessage(dict, replyHandler: nil, errorHandler: { (error: NSError) in
                    NSLog("Error: %@", error)
                })
            #endif
        } else {
            print("Can't send user info \(dict)")
        }
    }
    
    public func sendFile(fileURL: NSURL) {
        session?.transferFile(fileURL, metadata: nil)
    }
    
    //Keep track of the watch app status
    #if os(iOS)
    public func sessionWatchStateDidChange(_session: WCSession) {
        debugPrint("Watch State Did Change")
        //if (!_session.paired && !_session.watchAppInstalled) {
            //self.session = nil
        //} else if (self.session == nil) {
            //self.session = WCSession.defaultSession()
    }
    #endif
    
    @available(iOS 9.3, *)
    public func session(session: WCSession, activationDidCompleteWithState activationState: WCSessionActivationState, error: NSError?) {
        do {
            try session.updateApplicationContext(context)
            //Wake up the phone app
            #if os(watchOS)
                session.sendMessage([" ":""], replyHandler: nil, errorHandler: nil)
            #endif
        } catch {
            debugPrint("Error on update context")
        }
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        monitor?.incomingMessageReceive(message)
        debugPrint("Receive Message")
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        monitor?.incomingMessageReceive(userInfo)
        debugPrint("Receive User Info")
    }
    
    #if os(iOS)
    public func sendComplicationInfo(dict: [String: AnyObject]) {
        var updated = false;
        debugPrint("Send Complication")
        //Update context
        if let complicationList = session?.receivedApplicationContext["ComplcationKeys"] as? [String] {
            for key in dict.keys {
                if complicationList.contains(key) {
                    context[key] = dict[key]
                    updated = true
                }
            }
        }
        if (updated) {
            contextUpdate(context)
        }
    }
    #endif
    
    #if os(watchOS)
    public func subscribeKeys(keys: [String]) {
        debugPrint("Update subscribe")
        //Update context
        context["ComplcationKeys"] = keys
        contextUpdate(context)
    }
    #endif
    
    public func receivedInfo()->[String: AnyObject]? {
        return session?.receivedApplicationContext
    }
    
    public func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        #if os(iOS)
            if let keys = applicationContext["ComplcationKeys"] as? [String] {
            for key in keys {
                let (date, data) = CacheStorageSpace.commonStorageSpace.newestValueForKey(key)!
                let pt = watchDataPoint(key: key, data: data, lastUpdatedTime: date)
                let packet = NSKeyedArchiver.archivedDataWithRootObject(pt)
                contextUpdate([key: packet])
            }
            }
        #endif
    }
    
    private func contextUpdate(context: [String: AnyObject]) {
        debugPrint("Context Update")
        do {
            if (canSendMessage()) {
                try session?.updateApplicationContext(context)
            } else {
                debugPrint("Hasn't print")
            }
        } catch {
            debugPrint("Context Update error")
        }
    }
    
}
