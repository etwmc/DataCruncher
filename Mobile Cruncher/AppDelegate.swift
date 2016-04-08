
//
//  AppDelegate.swift
//  Mobile Cruncher
//
//  Created by Wai Man Chan on 1/4/16.
//
//

import UIKit
import CloudKit
import CruncherCore

class mobileMonitorGlobalObj {
    static let shareObj = mobileMonitorGlobalObj()
    let cruncherCoreQueue = dispatch_queue_create("Cruncher Queue", DISPATCH_QUEUE_CONCURRENT)
}

class backgroundToken: NSObject {
    public var token = UIBackgroundTaskInvalid
    public var timer: NSTimer! = nil
    override init() {
        super.init()
        timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: UIApplication.sharedApplication().delegate as! AppDelegate, selector: "scheduledBackgroundWrap:", userInfo: self, repeats: false)
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    var window: UIWindow?
    var taskID: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    let privateDB = CKHelperFunction().getDatabase(true)
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        watchSyncProtocol.initProtocol()
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self
        
        application.registerForRemoteNotifications()
        let notificationSetting = UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: nil)
        application.registerUserNotificationSettings(notificationSetting)
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        //print(deviceToken)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        let token = backgroundToken()
        print("Push")
        token.token = application.beginBackgroundTaskWithExpirationHandler { () -> Void in
            if (token.token != UIBackgroundTaskInvalid) {
                application.endBackgroundTask(token.token)
            }
        }
        handleFrameworkRemoteNotifcation(userInfo) { (notification: [NSObject : AnyObject]) -> Void in
            
        }
        //application.endBackgroundTask(self.taskID)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let token = backgroundToken()
        token.token = application.beginBackgroundTaskWithExpirationHandler { () -> Void in
            if (self.taskID != UIBackgroundTaskInvalid) {
                application.endBackgroundTask(token.token)
            }
        }
        handleFrameworkRemoteNotifcation(userInfo) { (notification: [NSObject : AnyObject]) -> Void in
            
        }
        completionHandler(.NewData)
    }
    
    func scheduledBackgroundWrap(timer: NSTimer) {
        if let token = timer.userInfo as? backgroundToken {
            UIApplication.sharedApplication().endBackgroundTask(token.token)
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Split view
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
    
}

