//
//  CCKeyValueStorage_Priv.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#ifndef CCKeyValueStorage_Priv_h
#define CCKeyValueStorage_Priv_h

#import <CoreData/CoreData.h>
#import "CCStorage.h"
#import "CCStorageBucket.h"

#import "Storage+CoreDataProperties.h"

typedef enum : NSUInteger {
    CCStorageType_noDefine,
    CCStorageType_keyValue,
} CCStorageType;

typedef enum : NSUInteger {
    CCStorageRootClass_Storage,
    CCStorageRootClass_Bucket,
} CCStorageRootClass;

NSDictionary * _Nonnull configurationFromData(NSData * _Nonnull confData);
NSData * _Nonnull configurationFromDict(NSDictionary * _Nonnull confDict);

@interface CCStorage (CCStorage_Priv)
+ (NSManagedObjectContext * _Nonnull)storageContext;
//Storage Management
+ (instancetype _Nonnull)createStorageWithConfDict:(NSDictionary * _Nullable)confDict;
- (NSData * _Nonnull)confData;
//Bucket Management
- (CCStorageBucket * _Nonnull)createBucket:(NSString * _Nonnull)bucket withConfDict:(NSDictionary * _Nonnull)confDict;
- (CCStorageBucket * _Nullable)fetchBucket:(NSString * _Nonnull)bucketName withConfDict:(NSDictionary * _Nullable)confDict;
//
- (void)save;
@end

#endif /* CCKeyValueStorage_Priv_h */
