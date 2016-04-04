//
//  CCStorage.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import "CCStorage.h"
#import "CCStorage_Priv.h"

#import <CoreData/CoreData.h>

#import "Storage+CoreDataProperties.h"
#import "Bucket.h"

#import "CCStorageBucket_Priv.h"

#import <CruncherCore/CruncherCore-Swift.h>

#import "CCStorageContextManager.h"


NSDictionary *configurationFromData(NSData *confData) {
    return [NSJSONSerialization JSONObjectWithData:confData options:0 error:nil];
}

NSData *configurationFromDict(NSDictionary *confDict) {
    return [NSJSONSerialization dataWithJSONObject:confDict options:0 error:nil];
}

NSString *CCStorageClassName(CCStorageType storageType, CCStorageRootClass class) {
    NSString *str = @"CC";
    switch (storageType) {
        case CCStorageType_keyValue:
            str = [str stringByAppendingString:@"KeyValue"];
            break;
        case CCStorageType_noDefine:
            NSCAssert(false, @"THe storage type has no defined, which is problematic");
    }
    switch (class) {
        case CCStorageRootClass_Storage:
            str = [str stringByAppendingString:@"Storage"];
            break;
        case CCStorageRootClass_Bucket:
            str = [str stringByAppendingString:@"StorageBucket"];
            break;
    }
    return str;
}

@interface CCStorage () {
    //Storage *mainStorage, *tempStorage;
    NSDictionary *storageConfDict;
#if TARGET_OS_IOS || TARGET_OS_WATCH
    ProtocolCipher *watchProtocol;
#endif
#if (TARGET_OS_IOS || TARGET_OS_MAC)&&!TARGET_OS_WATCH
    DeviceConsolidate *consolidate;
#endif
}
@end

@implementation CCStorage

//Interface
- (instancetype)initWithStorageConf:(NSDictionary *)confDict {
    self = [super init];
    if (self) {
        storageConfDict = confDict;
        
#if TARGET_OS_IOS || TARGET_OS_WATCH
        watchProtocol = [ProtocolCipher watchConnectiveCipher];
#endif
#if (TARGET_OS_IOS || TARGET_OS_MAC)&&!TARGET_OS_WATCH
        consolidate = [DeviceConsolidate shareConsolidate];
#endif
        
        
    }
    return self;
}

+ (instancetype _Nonnull)sharedStorage {
    NSCAssert(false, @"Don't touch abstract class");
    return [CCStorage new];
}

- (CCStorageBucket * _Nonnull)createStorageBucket:(NSString * _Nonnull)bucketName withHistoricalMode:(CCStorageHistoricalMode)mode {
    NSCAssert(false, @"Don't touch abstract class");
    return [CCStorageBucket new];
}

- (NSData *)confData {
    return configurationFromDict(storageConfDict);
}

- (CCStorageBucket *)createBucket:(NSString *)bucketName withConfDict:(NSDictionary *)confDict {
    NSManagedObjectContext *context = [CCStorage storageContext];
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    
    //If not found, set it up again
    __block Bucket *b;
    [context performBlockAndWait:^{
        b = [NSEntityDescription insertNewObjectForEntityForName:@"Bucket" inManagedObjectContext:context];
        
        b.confData = configurationFromDict(confDict);
        b.name = bucketName;
        
        [context refreshObject:b mergeChanges:YES];
        
        [mainStorage addBucketObject:b];
        
        
    }];
    
    [self save];
    
    NSString *typeName = CCStorageClassName(((NSNumber *) confDict[@"Type"]).unsignedIntegerValue, CCStorageRootClass_Bucket);
    CCStorageBucket *bucket = [[NSClassFromString(typeName) alloc] initWithBucket:b];
    return bucket;
}

- (CCStorageBucket * _Nullable)fetchBucket:(NSString *)bucketName {
    
    NSManagedObjectContext *context = [CCStorage storageContext];
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", bucketName];
    
    __block NSSet <Bucket*> *result = NULL;
    [context performBlockAndWait:^{
        result = [mainStorage.bucket filteredSetUsingPredicate:predicate];
    }];
    NSDictionary *confDict = configurationFromData(result.anyObject.confData);
    NSString *typeName = CCStorageClassName(((NSNumber *) confDict[@"Type"]).unsignedIntegerValue, CCStorageRootClass_Bucket);
    if (result.count > 0) {
        if (result.count > 1) {
            //Multiple bucket of the same name, so merge
            Bucket *remainBucket = result.anyObject;
            for (Bucket *otherBucket in result) {
                if (otherBucket != remainBucket) {
                    [remainBucket addData:otherBucket.data];
                    [mainStorage.managedObjectContext deleteObject:otherBucket];
                }
                [mainStorage.managedObjectContext performBlock:^{
                    [mainStorage.managedObjectContext save:nil];
                }];
            }
            return [[NSClassFromString(typeName) alloc] initWithBucket:remainBucket];
        } else {
            CCStorageBucket *bucket = [[NSClassFromString(typeName) alloc] initWithBucket:result.anyObject];
            return bucket;
        }
    } else return nil;

    return result;
}

- (CCStorageBucket * _Nullable)fetchBucket:(NSString *)bucketName withConfDict:(NSDictionary *)confDict {
    
    NSManagedObjectContext *context = [CCStorage storageContext];
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name == %@", bucketName];
    NSSet *result = [mainStorage.bucket filteredSetUsingPredicate:predicate];
    NSString *typeName = CCStorageClassName(((NSNumber *) confDict[@"Type"]).unsignedIntegerValue, CCStorageRootClass_Bucket);
    if (result.count > 0) {
        if (result.count > 1) {
            //Multiple bucket of the same name, so merge
            Bucket *remainBucket = result.anyObject;
            for (Bucket *otherBucket in result) {
                if (otherBucket != remainBucket) {
                    [remainBucket addData:otherBucket.data];
                    [mainStorage.managedObjectContext deleteObject:otherBucket];
                }
                [mainStorage.managedObjectContext performBlock:^{
                    [mainStorage.managedObjectContext save:nil];
                }];
            }
            return [[NSClassFromString(typeName) alloc] initWithBucket:remainBucket];
        } else {
            CCStorageBucket *bucket = [[NSClassFromString(typeName) alloc] initWithBucket:result.anyObject];
            return bucket;
        }
    } else return nil;
}

- (NSSet <CCStorageBucket*> *)fetchAllBucket {
    NSManagedObjectContext *context = [CCStorage storageContext];
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    
    NSMutableSet *buckets = [NSMutableSet set];
    for (Bucket *b in mainStorage.bucket) {
        __block NSData *bucketConfData;
        [context performBlockAndWait:^{
            bucketConfData = [b confData];
        }];
        NSDictionary *confDict = configurationFromData(bucketConfData);
        NSString *typeName = CCStorageClassName(((NSNumber *) confDict[@"Type"]).unsignedIntegerValue, CCStorageRootClass_Bucket);
        CCStorageBucket *bucket = [[NSClassFromString(typeName) alloc] initWithBucket:b];
        [buckets addObject:bucket];
    }
    return buckets;
}

- (void)deleteBucket:(CCStorageBucket * _Nonnull)bucket {
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    
    if ([mainStorage.bucket containsObject:[bucket obj]]) {
        [mainStorage removeBucketObject:bucket.obj];
        [self save];
    }
}

- (void)save {
    
    NSManagedObjectContext *context = [CCStorage storageContext];
    Storage *mainStorage = [CCStorage storageInstanceFromConf:storageConfDict];
    
    [context performBlock:^{
        [[CCStorage storageContext] refreshObject:mainStorage mergeChanges:YES];
        NSError *error = nil;
        if ([[CCStorage storageContext] hasChanges]) [[CCStorage storageContext] save:&error];
        if (error != nil) {
            NSLog(@"Save error: %@", error);
        }
    }];
    
}

- (void)saveStorage {
    [self save];
}

- (void)endingSave
{
    
    /*NSPersistentStoreCoordinator *coord = [CCStorage persistentStoreCoordinator];
    for (NSPersistentStore *store in coord.persistentStores) {
        NSError *error;
        [coord removePersistentStore:store error:&error];
        NSLog(@"Quit error %@", error);
    }*/
    
}

- (void)createMirrorDB:(void(^)(NSURL *storageURL))finishBlock {
    NSManagedObjectContext *context = [CCStorage storageContext];
    
    NSString *folder = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true)[0];
    NSURL *fileURL = [NSURL fileURLWithPath:[folder stringByAppendingPathComponent:@"watchDB"]];
    
    NSPersistentStoreCoordinator *coord = context.persistentStoreCoordinator;
    
    NSPersistentStore *oldStore = coord.persistentStores[0];
    
    NSError *error;
    
    NSPersistentStore *store = [coord migratePersistentStore:oldStore toURL:fileURL options:@{NSSQLitePragmasOption:@{@"journal_mode":@"DELETE"}} withType:NSSQLiteStoreType error:&error];
    
    
    if (!error) {
        [coord migratePersistentStore:store toURL:oldStore.URL options:oldStore.options withType:oldStore.type error:&error];
        if (!error)
            finishBlock(fileURL);
        else NSLog(@"%@", error);
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    } else NSLog(@"%@", error);
}

//Actual implement

+ (NSManagedObjectContext * _Nonnull)storageContext {
    if ([CCStorage contextImported]) {
        return [CCStorage cloudContext];
    } else {
        return [CCStorage cacheContext];
    }
}
+ (NSManagedObjectContext * _Nonnull)cloudContext {
    return [CCStorageContextManager sharedManager].managedContext;
}
+ (NSManagedObjectContext * _Nonnull)cacheContext {
    return [CCStorageContextManager sharedManager].managedContext;
}

+ (BOOL)contextImported {
    return [CCStorageContextManager sharedManager].contextImported;
}

+ (Storage *)storageInstanceFromConf:(NSDictionary *)confDict {
    NSManagedObjectContext *context = [self storageContext];
    
    __block Storage *s = nil;
    [context performBlockAndWait:^{
        NSError *error;
        
        //First, ensure such bucket does not exist
        NSFetchRequest *fetchReq = [NSFetchRequest fetchRequestWithEntityName:@"Storage"];
        NSLog(@"Conf: %@", confDict);
        NSData *confData = configurationFromDict(confDict);
        NSLog(@"Data: %@", confData);
        fetchReq.predicate = [NSPredicate predicateWithFormat:@"self.type == %@ && self.confData == %@", confDict[@"Type"], confData];
        NSArray *storages = [context executeFetchRequest:fetchReq error:&error];
        
        NSLog(@"Error: %@", error);
        NSLog(@"Storages: %d", storages.count);
        
        for (Storage *_s in storages) {
            if ([_s.confData isEqualToData:confData]) {
                //Verify: same name, same configuartion
                s = _s;
                return;
            }
        }
        
        //If there is nothing, create
        if (storages.count == 0) {
            s = [NSEntityDescription insertNewObjectForEntityForName:@"Storage" inManagedObjectContext:context];
            s.confData = configurationFromDict(confDict);
            s.type = confDict[@"Type"];
            [context save:nil];
        }
    }];
    return s;
}

+ (instancetype)createStorageWithConfDict:(NSDictionary *)confDict {
    
    NSString *typeName = CCStorageClassName(((NSNumber *) confDict[@"Type"]).unsignedIntegerValue, CCStorageRootClass_Storage);
    
    CCStorage *storage = [[NSClassFromString(typeName) alloc] initWithStorageConf:confDict];
    return storage;
    
}

@end
