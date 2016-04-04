//
//  ProtocolCipher.swift
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/7/16.
//
//

import Foundation

public typealias protocolCallback = (key: String, value: AnyObject)->Void
public typealias updateMessageCallback = ()->AnyObject?

//Routing message to correspondent callback

public class ProtocolCipher: NSObject {
    enum cipherType {
        case Push, WatchConnective
    }
    static public let pushNotificationCipher = ProtocolCipher(.Push)
    #if os(iOS) || os(watchOS)
    static public let watchConnectiveCipher = ProtocolCipher(.WatchConnective)
    #endif
    let type: cipherType
    private init(_ type: cipherType) {
        self.type = type;
        super.init()
        switch type {
        case .WatchConnective:
            #if os(iOS) || os(watchOS)
                WatchSession.defaultSession.monitor = self
            #endif
            break
        default:
            break
        }
    }
    //Receiving End
    private var callbackMap: [String: protocolCallback] = [:]
    private let callbackMapLock = dispatch_semaphore_create(1)
    public func addCallback(name: String, _ callback: protocolCallback) {
        dispatch_semaphore_wait(callbackMapLock, DISPATCH_TIME_FOREVER)
        callbackMap[name] = callback
        dispatch_semaphore_signal(callbackMapLock)
    }
    public func removeCallback(name: String) {
        dispatch_semaphore_wait(callbackMapLock, DISPATCH_TIME_FOREVER)
        callbackMap.removeValueForKey(name)
        dispatch_semaphore_signal(callbackMapLock)
    }
    public func incomingMessageReceive(dict: [String: AnyObject]) {
        for (key, value) in dict {
            
            if let callback = callbackMap[key] {
                #if os(iOS)
                #endif
                callback(key: key, value: value)
            }
            
        }
    }
    
    //Sending End
    private var nextMessage: [String: AnyObject] = [:]
    private let messageLock = dispatch_semaphore_create(1)
    private var routineUpdater: [String: updateMessageCallback] = [:]
    private let updaterLock = dispatch_semaphore_create(1)
    public func addUpdater(name: String, _ callback: updateMessageCallback) {
        dispatch_semaphore_wait(updaterLock, DISPATCH_TIME_FOREVER)
        routineUpdater[name] = callback
        dispatch_semaphore_signal(updaterLock)
    }
    public func removeUpdater(name: String) {
        dispatch_semaphore_wait(updaterLock, DISPATCH_TIME_FOREVER)
        routineUpdater.removeValueForKey(name)
        dispatch_semaphore_signal(updaterLock)
    }
    public func addMessage(key: String, value: AnyObject) {
        dispatch_semaphore_wait(messageLock, DISPATCH_TIME_FOREVER)
        if (self.type == .WatchConnective) {
            switch value {
            case is NSCoding:
                nextMessage[key] = value;
            default:
                print("Watch Connective only support serializable value")
            }
        }
        dispatch_semaphore_signal(messageLock)
    }
    public func outgoingMessageFlush()->Bool {
        for (key, callback) in routineUpdater {
            if (!nextMessage.keys.contains(key)) {
                //If does not contain a value, ask the updater if it wants to update
                if let reply = callback() {
                    //Got message back
                    addMessage(key, value: reply)
                }
                
            }
        }
        
        //Check availability
        let available: Bool
        if (self.type == .WatchConnective) {
            #if !os(OSX)
            available = WatchSession.defaultSession.canSendMessage()
            #endif
        } else { return false }
        
        dispatch_semaphore_wait(messageLock, DISPATCH_TIME_FOREVER)
        let currentMessage = nextMessage
        nextMessage = [:]
        dispatch_semaphore_signal(messageLock)
        
        if (self.type == .WatchConnective) {
            #if !os(OSX)
            if (available) {
                WatchSession.defaultSession.sendUserInfo(currentMessage)
                }
            #endif
        }
        
        return true
        
    }
    
}
