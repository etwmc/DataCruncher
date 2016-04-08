//
//  CCStorageBucket.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import "CCStorageBucket.h"
#import "Bucket.h"
#import "CCStorageBucket_Priv.h"
#import "CCData_Priv.h"
#import "CCData.h"

#import "CCProcessor.h"

#if !TARGET_OS_WATCH
#import <CloudKit/CloudKit.h>
#endif

#import <CruncherCore/CruncherCore-Swift.h>

@interface CCStorageBucket (){
    Bucket *bucketObj;
#if !TARGET_OS_WATCH
    CKRecord *lastUpdatedRecord;
    CKDatabase *database;
    NSData *lastData; CCData *lastCCData;
    int retryCounter;
#endif
}
@end

#if !TARGET_OS_WATCH
@interface CCStorageBucketRecordDelegate : NSObject {
    NSTimer *timer;
}
+ (instancetype)sharedDelegate;
@end
@implementation CCStorageBucketRecordDelegate

+ (instancetype)sharedDelegate {
    static CCStorageBucketRecordDelegate *delegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [CCStorageBucketRecordDelegate new];
    });
    return delegate;
}

- (NSMutableSet *)chagedRecordSet {
    static NSMutableSet *set = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [NSMutableSet new];
    });
    return set;
}

- (void)addRecord:(CKRecord *)record {
    if (record) {
        NSMutableSet *set = [self chagedRecordSet];
        bool previouslyExist = [set containsObject:record];
        [set addObject:record];
        if (!previouslyExist) {
            if (timer) {
                [timer invalidate];
            }
            
            timer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(autoSave:) userInfo:nil repeats:false];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            });
        }
    }
    
    
}

- (void)autoSave:(NSTimer *)_timer {
    
    timer = nil;
    
    CKDatabase *database = [CKContainer containerWithIdentifier:@"iCloud.WMC.DataCruncher"].publicCloudDatabase;
    
    __block UInt8 retry = 0;
    
    void (^ckResaveHandler)(NSArray <CKRecord *> *, NSArray <CKRecordID *> *, NSError *) = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *error) {
        [[self chagedRecordSet] minusSet:[NSSet setWithArray:savedRecords]];
        if (error) {
            if (retry < 1 && error.code == CKErrorZoneBusy) {
                retry++;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[self chagedRecordSet].allObjects recordIDsToDelete:nil];
                        [op setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable error) {
                            if (error) {
                                for (CKRecord *record in savedRecords) {
                                    [[CKHelperFunction new] resetRecord:true record:record];
                                }
                            }
                        }];
                        op.savePolicy = CKRecordSaveChangedKeys;
                        [database addOperation:op];

                });
            } else if (error.code == CKErrorServerRecordChanged) {
                dispatch_async(processorMessageQueue, ^{
                });
            } else {
                //Unknown error, so delete everything and start again
            }
            NSLog(@"%@", error);
        }
    };
    
    CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:[self chagedRecordSet].allObjects recordIDsToDelete:@[]];
    op.modifyRecordsCompletionBlock = ckResaveHandler;
    op.savePolicy = CKRecordSaveChangedKeys;
    op.atomic = true;
    op.database = database;
    [database addOperation:op];
}

@end
#endif

@implementation CCStorageBucket

- (NSOrderedSet <CCData*> * _Nonnull)convertCDToObj:(NSOrderedSet <Data*> *)rawData {
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSetWithCapacity:rawData.count];
    [rawData enumerateObjectsWithOptions:0 usingBlock:^(Data * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CCData *d = [[CCData alloc] init:obj];
        [set insertObject:d atIndex:idx];
    }];
    return set;
}

- (NSOrderedSet <CCData *>*)allData {
    return [self convertCDToObj:bucketObj.data];
}

- (NSOrderedSet <CCData *>*)dataFilteredWithPredicate:(NSPredicate *)predicate {
    if (bucketObj.data == NULL) return [NSOrderedSet orderedSet];
    NSOrderedSet *set = [NSOrderedSet orderedSetWithSet:bucketObj.data];
    return [self convertCDToObj:[set filteredOrderedSetUsingPredicate:predicate]];
}

- (NSOrderedSet <CCData *>*)lastestData:(NSUInteger)numberOfRecord {
    NSInteger startIndex = bucketObj.data.count-numberOfRecord-1;
    //if (startIndex < 0) startIndex = 0;
    //if (numberOfRecord > bucketObj.data.count) numberOfRecord = bucketObj.data.count;
    NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"insertDate" ascending:false];
    __block NSArray *array;
    [bucketObj.managedObjectContext performBlockAndWait:^{
        array = [bucketObj.data sortedArrayUsingDescriptors:@[desc]];
    }];
    NSOrderedSet *newSet = [NSOrderedSet orderedSetWithArray:array range:NSMakeRange(0, numberOfRecord<=array.count? numberOfRecord: array.count) copyItems:NO];
    return [self convertCDToObj:newSet];
}

#if !TARGET_OS_WATCH
- (void)initCloudKit {
    database = [CKContainer containerWithIdentifier:@"iCloud.WMC.DataCruncher"].publicCloudDatabase;
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:@"LastestValue" predicate:[NSPredicate predicateWithFormat:@"bucketName = %@", bucketObj.name]];
    
    [[CKHelperFunction new] getUniqueRecordWithID:true query:query recreateRecord:^CKRecord * _Nonnull{
        CKRecord *record = [[CKRecord alloc] initWithRecordType:@"LastestValue"];
        [record setObject:bucketObj.name forKey:@"bucketName"];
        return record;
    } completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
        if (error) {
            //Unrecoverable error
        } else {
            lastUpdatedRecord = record;
            
            
            if ([self monitor]) {
                [[bucketMonitorManger sharedManager] registerBucketMonitor:self];
            }
            
            //Subscribe
            NSString *subscritionName = [NSString stringWithFormat:@"%@-Subscribe", bucketObj.name];
            [[CKHelperFunction new] getUniqueSubscriberWithID:true subscribeID:subscritionName createSubscribtion:^CKSubscription * _Nonnull{
                CKSubscription*subsciption = [[CKSubscription alloc] initWithRecordType:@"LastestValue" predicate:[NSPredicate predicateWithFormat:@"recordID == %@", record.recordID] subscriptionID: subscritionName options:CKSubscriptionOptionsFiresOnRecordUpdate];
                subsciption.notificationInfo = [[CKNotificationInfo alloc] init];
                subsciption.notificationInfo.alertBody = @"";
                subsciption.notificationInfo.soundName = @"";
                subsciption.notificationInfo.shouldSendContentAvailable = true;
                subsciption.notificationInfo.category = @"Bucket_Update";
                return subsciption;
            } completionHandler:^(CKSubscription * _Nullable subsciption, NSError * _Nullable error) {
                if (error)
                    NSLog(@"%@", error);
                else {
                    subsciption.notificationInfo = [[CKNotificationInfo alloc] init];
                    subsciption.notificationInfo.alertBody = @"";
                    subsciption.notificationInfo.soundName = @"";
                    subsciption.notificationInfo.shouldSendContentAvailable = true;
                    subsciption.notificationInfo.category = @"Bucket_Update";
                    //Ensure the record ID didn't change in the process
                    [[[CKHelperFunction new] getDatabase:true] saveSubscription:subsciption completionHandler:^(CKSubscription * _Nullable subscription, NSError * _Nullable error) {
                        NSLog(@"Subscript Bucket: %@", error);
                    }];
                }
            }];
            
        }
    }];
}
#endif

- (instancetype)initWithBucket:(Bucket *)b {
    self = [super init];
    if (self) {
        bucketObj = b;
#if !TARGET_OS_WATCH
        NSOrderedSet <CCData *>*lastest = [self lastestData:1];
        lastCCData = lastest.firstObject;
        lastData = lastCCData.obj.value;
        [self initCloudKit];
        retryCounter = 0;
#endif
    }
    return self;
}

- (NSData *)confData { return bucketObj.confData; }

- (NSString *)bucketName {
    return bucketObj.name;
}

#if !TARGET_OS_WATCH
- (CCData *)insertData:(NSData *)data {
    
    if (lastData == nil) {
        NSOrderedSet <CCData *>*lastest = [self lastestData:1];
        lastCCData = lastest.firstObject;
        lastData = lastCCData.obj.value;
        
    }
    
    __block Data *obj;
    NSDate *insertDate = [NSDate date];
    
    if (![data isEqualToData:lastData] || retryCounter >= 10) {
        [lastUpdatedRecord setObject:data forKey:@"data"];
        [lastUpdatedRecord setObject:insertDate forKey:@"updateTime"];
        
        [[CCStorageBucketRecordDelegate sharedDelegate] addRecord:lastUpdatedRecord];
        retryCounter = 0;
    } else {
        retryCounter++;
        return lastCCData;
    }
    
    [bucketObj.managedObjectContext performBlockAndWait:^{
        
        obj = [NSEntityDescription insertNewObjectForEntityForName:@"Data" inManagedObjectContext:[CCStorage storageContext]];
        
        obj.value = data;
        obj.insertDate = insertDate;
        [bucketObj addDataObject:obj];
        
    }];
    
    lastData = data;
    
    
//    void (^ckResaveHandler)(NSArray <CKRecord *> *, NSArray <CKRecordID *> *, NSError *) = ^(NSArray <CKRecord *> *savedRecords, NSArray <CKRecordID *> *deletedRecordIDs, NSError *error) {
//        if (error) {
//            if (retry < 1 && error.code == CKErrorZoneBusy) {
//                retry++;
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    
//                    if (lastUpdatedRecord) {CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[lastUpdatedRecord] recordIDsToDelete:nil];
//                        [op setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable error) {
//                            if (error) {
//                                [[CKHelperFunction new] resetRecord:true record:lastUpdatedRecord];
//                                [self initCloudKit];
//                            }
//                        }];
//                        op.savePolicy = CKRecordSaveChangedKeys;
//                        [database addOperation:op];
//                    }
//                });
//            } else if (error.code == CKErrorServerRecordChanged) {
//                dispatch_async(processorMessageQueue, ^{
//                    [self initCloudKit];
//                    [self insertData:data];
//                });
//            } else {
//                //Unknown error, so delete everything and start again
//                [[CKHelperFunction new] resetRecord:true record:lastUpdatedRecord];
//                [self initCloudKit];
//            }
//            NSLog(@"%@", error);
//        }
//    };
//    
//    if (lastUpdatedRecord) {
//        CKModifyRecordsOperation *op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[lastUpdatedRecord] recordIDsToDelete:nil];
//        op.modifyRecordsCompletionBlock = ckResaveHandler;
//        op.savePolicy = CKRecordSaveChangedKeys;
//        [database addOperation:op];
//    }
    
    lastCCData = [[CCData alloc] init:obj];
    
    return lastCCData;
}

- (void)removeData:(CCData *)data {
    
}
#endif

//Bucket ability of monitor

#if !TARGET_OS_WATCH

#define bucketMonitorDefaultKey @"Monitor"

- (void)setMonitor:(BOOL)state {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSArray *oldMonitors = [store arrayForKey:bucketMonitorDefaultKey];
    NSMutableArray *newMonitors = [NSMutableArray arrayWithArray:oldMonitors];
    if (state) {
        if (![newMonitors containsObject:bucketObj.name]) {
            [newMonitors addObject:bucketObj.name];
            [[bucketMonitorManger sharedManager] registerBucketMonitor:self];
        }
    } else {
        [newMonitors removeObject:bucketObj.name];
        [[bucketMonitorManger sharedManager] deregisterBucketMonitor:self];
    }
    [store setArray:newMonitors forKey:bucketMonitorDefaultKey];
    [store synchronize];
}

- (BOOL)monitor {
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSArray *oldMonitors = [store arrayForKey:bucketMonitorDefaultKey];
    return [oldMonitors containsObject:bucketObj.name];
}

- (CKRecordID *)recordID { return lastUpdatedRecord.recordID; }
#endif

@end