//
//  CCStorageContextManager.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CCStorageContextManager : NSObject {
    dispatch_queue_t storageQueue;
    NSOperationQueue *queue;
    dispatch_semaphore_t ubiquiousImported;
    
    NSManagedObjectContext *context;
    NSManagedObjectContext *cacheCtx;
    
    id<NSObject> storeWillChangeNotification;
    id<NSObject> storeDidChangeNotification;
    id<NSObject> contextWillSave;
    id<NSObject> storeDidImport;
}
@property (readonly) NSManagedObjectContext *managedContext;
@property (readonly) NSManagedObjectContext *cacheManagedContext;
+ (instancetype)sharedManager;
- (void)relaseContext;
- (void)waitForImport;
@property (readonly) BOOL contextImported;
@end
