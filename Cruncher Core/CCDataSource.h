//
//  CCDataSource.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <CruncherCore/CCProcessor.h>
#elif TARGET_OS_WATCH
#import <CruncherCore/CCProcessor.h>
#elif TARGET_OS_MAC
#import <CruncherCore/CCProcessor.h>
#endif

typedef void(^CCDataFetchSuccess)(NSData *_Nonnull);
typedef void(^CCDataFetchFail)(NSError*_Nonnull);

@interface CCDataSource : CCProcessor
- (void)fetchData:(CCDataFetchSuccess _Nonnull)successBlock errorBlock:(CCDataFetchFail _Nonnull)failedBlock;
@end