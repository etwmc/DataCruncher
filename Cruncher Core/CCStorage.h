//
//  CCStorage.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum : NSUInteger {
    CCStorageHistoricalMode_NoHistory,
    CCStorageHistoricalMode_Linear,
} CCStorageHistoricalMode;

@class CCStorageBucket;
@class Storage;

@protocol CCStorageManagementProtocol <NSObject>
- (void)bucketAdded  :(CCStorageBucket *_Nonnull)newBucket;
- (void)bucketUpdated:(CCStorageBucket *_Nonnull)bucket;
- (void)bucketRemoved:(CCStorageBucket *_Nonnull)oldBucket;
@end

@interface CCStorage : NSObject
@property (readwrite) NSObject <CCStorageManagementProtocol> *_nullable;
+ (NSURL * _Nonnull)historyDBAddr;
- (instancetype _Nonnull)initWithStorageConf:(NSDictionary *_Nonnull)confDict;
+ (instancetype _Nonnull)sharedStorage;
- (void)saveStorage;
- (CCStorageBucket * _Nonnull)createStorageBucket:(NSString * _Nonnull)bucketName withHistoricalMode:(CCStorageHistoricalMode)mode;
- (CCStorageBucket * _Nullable)fetchBucket:(NSString *_Nonnull)bucketName;
- (CCStorageBucket * _Nullable)fetchBucket:(NSString *_Nonnull)bucketName withHistoricalMode:(CCStorageHistoricalMode)mode;
- (NSSet <CCStorageBucket*> * _Nullable)fetchAllBucket;
+ (void)deleteBucket:(CCStorageBucket * _Nonnull)bucket;
+ (NSManagedObjectContext * _Nonnull)storageContext;

@end
