//
//  AppDelegate.swift
//  Background Cruncher
//
//  Created by Wai Man Chan on 12/25/15.
//
//

import Cocoa
import CruncherCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    var items: [BCItem] = []
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    let queue = dispatch_queue_create("Main Queue", DISPATCH_QUEUE_CONCURRENT)
    
    let containersManager = CCProcessorContainerManager.sharedManager
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        SleepDerviation.stopSleep()
        
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: #selector(AppDelegate.goingToSleep(_:)), name: NSWorkspaceWillSleepNotification, object: nil)
        
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: #selector(AppDelegate.wakeFromSleep(_:)), name: NSWorkspaceDidWakeNotification, object: nil)
        
        let menu = NSMenu()
        
        self.statusItem.menu = menu
        
        let loadingState = NSMenuItem(title: "Loading", action: nil, keyEquivalent: "")
        menu.addItem(loadingState)
        
        menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.sharedApplication().terminate(_:)), keyEquivalent: "q"))
        
        if let button = self.statusItem.button {
            button.image = NSImage(named: "StatusIcon-Wait")
            button.image?.template = true
        }
        
        dispatch_async(queue, { () -> Void in
            
            for (index, container) in self.containersManager.containers.enumerate() {
                let item = BCItem(container: container)
                self.items.append(item)
                
                let menuItem = NSMenuItem(title: item.container.containerName, action: nil, keyEquivalent: "")
                menuItem.representedObject = item
                item.label = menuItem
                
                //Create submenu
                //Last update time
                //Period
                //Manual Start
                let submenu = NSMenu()
                submenu.addItem(NSMenuItem(title: "Last Update: Not started", action: nil, keyEquivalent: ""))
                submenu.addItem(NSMenuItem(title: "Manual Update", action: #selector(AppDelegate.manualRefresh(_:)), keyEquivalent: ""))
                submenu.itemAtIndex(1)!.representedObject = item
                menuItem.submenu = submenu
                
                menu.insertItem(menuItem, atIndex: index*2+0)
                menu.insertItem(NSMenuItem.separatorItem(), atIndex: index*2+1)
                
            }
            
            if let button = self.statusItem.button {
                button.image = NSImage(named: "StatusIcon-Work")
                button.image?.template = true
            }
            
            menu.removeItem(loadingState)
            
            for menuItem in self.items {
                let item = menuItem
                _ = item.container.outputProcessors.map { (process: CCProcessor) -> Void in
                    process.processorStart()
                }
            }
            
        })
        
    }
    
    func goingToSleep(notify: NSNotification) {
        print("Sleep")
    }
    
    func wakeFromSleep(notify: NSNotification) {
        print("Wake\n")
        for menuItem in items {
            let item = menuItem
            _ = item.container.outputProcessors.map { (process: CCProcessor) -> Void in
                process.processorStart()
            }
        }
    }
    
    func manualRefresh(menuItem: NSMenuItem) {
        let item = menuItem.representedObject as! BCItem
        _ = item.container.outputProcessors.map { (process: CCProcessor) -> Void in
            process.processorStart()
        }
    }
    
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            //Wrap up
            CCKeyValueStorage.sharedStorage().saveStorage()
            sender.replyToApplicationShouldTerminate(true)
        };
        return NSApplicationTerminateReply.TerminateLater
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}

