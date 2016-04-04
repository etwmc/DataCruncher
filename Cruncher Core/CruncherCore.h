//
//  Cruncher Core.h
//  Cruncher Core
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#if !TARGET_OS_WATCH
#import <CloudKit/CloudKit.h>
#endif

//! Project version number for Cruncher Core.
FOUNDATION_EXPORT double Cruncher_CoreVersionNumber;

//! Project version string for Cruncher Core.
FOUNDATION_EXPORT const unsigned char Cruncher_CoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Cruncher_Core/PublicHeader.h>

#import <CruncherCore/CCStorage.h>
#import <CruncherCore/CCKeyValueStorage.h>

#import <CruncherCore/CCStorageBucket.h>
#import <CruncherCore/CCKeyValueStorageBucket.h>

#import <CruncherCore/CCData.h>

#import <CruncherCore/CCProcessor.h>

#import <CruncherCore/CCNetworkSource.h>
#import <CruncherCore/CCXMLParser.h>
#import <CruncherCore/CCDataSource.h>

#import <CruncherCore/CCStorageContextManager.h>