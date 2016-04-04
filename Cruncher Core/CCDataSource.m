//
//  CCDataSource.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import "CCDataSource.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

@interface CCDataSource() {
    CCProcessorOutputUpdate callback;
}
@end

@implementation CCDataSource

- (void)fetchData:(CCDataFetchSuccess)successBlock errorBlock:(CCDataFetchFail)failedBlock {
}

- (void)startProcessWithInput:(NSDictionary<NSString *,NSObject *> *)input complete:(CCProcessorOutputUpdate)completeBlock {
    [self fetchData:^(NSData * _Nonnull data) {
        completeBlock(@{@"Data": data});
    } errorBlock:^(NSError * _Nonnull error) {
        completeBlock(@{@"Error": error});
    }];
}

@end
