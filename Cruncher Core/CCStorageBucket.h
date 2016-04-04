//
//  CCStorageBucket.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH
#import <CloudKit/CloudKit.h>
#endif

@class CCData;

@interface CCStorageBucket : NSObject
- (NSOrderedSet <CCData *>*)allData;
- (NSOrderedSet <CCData *>*)dataFilteredWithPredicate:(NSPredicate *)predicate;
- (NSOrderedSet <CCData *>*)lastestData:(NSUInteger)numberOfRecord;
@property (readonly) NSString *bucketName;
#if !TARGET_OS_WATCH
@property (readonly) CKRecordID *recordID;
- (CCData *)insertData:(NSData *)data;
- (void)removeData:(CCData *)data;
- (void)setMonitor:(BOOL)state;
- (BOOL)monitor;
#endif
@end
