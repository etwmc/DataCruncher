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

@objc public protocol WatchSessionDelegate {
    optional func sessionHasComplicationUpdate(session: WatchSession, info: [String: NSObject])
}

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
    
    public override init() {
        super.init()
    }
    
    internal func sessionInit() {
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
        } else { session = nil }
        session?.delegate = self
        session?.activateSession()
    }
    
    public func canSendMessage()->Bool {
        if #available(iOS 9.3, *) {
            return (session != nil) && (session?.activationState == .Activated)
        } else {
            // Fallback on earlier versions
            return (session != nil)
        }
    }
    
    public func sendUserInfo(dict: [String: AnyObject]) {
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
    public func sessionWatchStateDidChange(_session: WCSession) {
        #if os(iOS)
            if (!_session.paired && !_session.watchAppInstalled) {
                self.session = nil
            } else if (self.session == nil) {
                self.session = WCSession.defaultSession()
            }
        #endif
    }
    
    public func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        monitor?.incomingMessageReceive(message)
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        monitor?.incomingMessageReceive(userInfo)
    }
    
    #if os(iOS)
    public func sendComplicationInfo(dict: [String: AnyObject]) {
        if (canSendMessage()) {
            session?.transferCurrentComplicationUserInfo(dict)
        } else {
            print("Can't send complication info \(dict)")
        }
    }
    #endif
    
    func contextUpdate(context: [String: AnyObject]) {
        do {
            if (canSendMessage()) {
                try session?.updateApplicationContext(context)
            }
        } catch {
            debugPrint("Context Update error")
        }
    }
    
    func context()->[String: AnyObject]? {
        return session?.receivedApplicationContext
    }
    
}
