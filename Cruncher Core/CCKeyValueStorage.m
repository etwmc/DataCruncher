//
//  CCKeyValueStorage.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import "CCKeyValueStorage.h"
#import "CCKeyValueStorageBucket.h"
#import "CCStorage_Priv.h"

@implementation CCKeyValueStorage

+ (instancetype _Nonnull)sharedStorage {
    static CCKeyValueStorage *storage = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CCStorage *s = [CCStorage createStorageWithConfDict:@{ @"Type": [NSNumber numberWithUnsignedInteger:CCStorageType_keyValue] }];
        NSCAssert([s isMemberOfClass:[CCKeyValueStorage class]], @"CCKeyValueStorage failed to create");
        storage = (CCKeyValueStorage *)s;
    });
    return storage;
}

- (CCStorageBucket * _Nonnull)createStorageBucket:(NSString * _Nonnull)bucketName withHistoricalMode:(CCStorageHistoricalMode)mode {
    return [self createBucket:bucketName withConfDict:@{ @"Mode": [NSNumber numberWithUnsignedInteger:mode],
                                                         @"Type": [NSNumber numberWithUnsignedInteger:CCStorageType_keyValue] }];
}

- (CCStorageBucket *)fetchBucket:(NSString *)bucketName withHistoricalMode:(CCStorageHistoricalMode)mode {
    return [self fetchBucket:bucketName withConfDict:@{ @"Mode": [NSNumber numberWithUnsignedInteger:mode],
                                                        @"Type": [NSNumber numberWithUnsignedInteger:CCStorageType_keyValue] }];
}

@end
