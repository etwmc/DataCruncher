//
//  CCNetworkSource.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <CruncherCore/CCDataSource.h>
#elif TARGET_OS_WATCH
#import <CruncherCore/CCDataSource.h>
#elif TARGET_OS_MAC
#import <CruncherCore/CCDataSource.h>
#endif

@interface CCNetworkSource : CCDataSource
- (instancetype)initWithURL:(NSURL *)sourceURL;
@property (readwrite) NSURL *url;
@property (readwrite) BOOL foregroundPriority;
@end
