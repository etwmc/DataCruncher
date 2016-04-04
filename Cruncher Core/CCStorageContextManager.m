//
//  CCStorageContextManager.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 2/14/16.
//
//

#import "CCStorageContextManager.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface NSManagedObjectContext (AutosaveExtension)
- (void)autosave:(NSTimer *)save;
- (void)didImportUbiquitousContentChanges:(NSNotification*) notification;
@end
@implementation NSManagedObjectContext (AutosaveExtension)
- (void)autosave:(NSTimer *)save {
    if (self.hasChanges)
        [self performBlock:^{
            [self save:nil];
            [self reset];
        }];
    else [self reset];
}
- (void)didImportUbiquitousContentChanges:(NSNotification*) notification {
    NSLog(@"Import Ubi: %@", notification);
}
@end

@implementation CCStorageContextManager

+ (instancetype)sharedManager {
    static CCStorageContextManager *manager = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CCStorageContextManager new];
    });
    return manager;
}

- (NSManagedObjectContext *)managedContext {
    //Get the context
    if (!context) {
        [self storageContext];
        [self waitForImport];
    }
    return context;
}

- (NSManagedObjectContext *)cacheManagedContext {
    //Get the context
    if (!context) {
        [self storageContext];
    }
    return context;
}

- (void)relaseContext {
    [self stopAutosave];
    context = nil;
}

//Private Helper

+ (NSManagedObjectModel *)storageModel {
    static NSManagedObjectModel *model = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"CCStorage" withExtension:@"momd"];
        model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    });
    return model;
}

+ (NSURL *)historyDBAddr {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSURL *groupURL = [manager containerURLForSecurityApplicationGroupIdentifier:@"group.WMC.cruncherCore"];
    groupURL = [groupURL URLByAppendingPathComponent:@"History" isDirectory:true];
    
    if (![manager fileExistsAtPath:groupURL.absoluteString isDirectory:nil]) {
        [manager removeItemAtURL:groupURL error:nil];
        [manager createDirectoryAtURL:groupURL withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    return [groupURL URLByAppendingPathComponent:@"storage.db"];
}

+ (NSURL *)cacheDBAddr {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSURL *groupURL = [manager containerURLForSecurityApplicationGroupIdentifier:@"group.WMC.cruncherCore"];
    groupURL = [groupURL URLByAppendingPathComponent:@"History" isDirectory:true];
    
    if (![manager fileExistsAtPath:groupURL.absoluteString isDirectory:nil]) {
        [manager removeItemAtURL:groupURL error:nil];
        [manager createDirectoryAtURL:groupURL withIntermediateDirectories:true attributes:nil error:nil];
    }
    
    return [groupURL URLByAppendingPathComponent:@"cache.db"];
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    static NSPersistentStoreCoordinator *coord = NULL;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self storageModel]];
        
        NSURL *persistentStoreURL = [self historyDBAddr];
        
        NSError *pscError = nil;
        if (![coord addPersistentStoreWithType:NSSQLiteStoreType
                                 configuration:nil
                                           URL:persistentStoreURL
                                       options:@{
                                                 NSInferMappingModelAutomaticallyOption: @YES,
                                                 NSMigratePersistentStoresAutomaticallyOption: @YES
#if !TARGET_OS_WATCH
                                                 , NSPersistentStoreUbiquitousContentNameKey: @"DataCruncherMonitor"
                                                 , NSPersistentStoreRebuildFromUbiquitousContentOption: @NO
#endif
                                                 }
                                         error:&pscError]) {
            NSLog(@"Error creating persistent store at %@: %@", persistentStoreURL, [pscError localizedDescription]);
        }
        
    });
    return coord;
}

+ (NSPersistentStoreCoordinator *)cacheStoreCoordinator {
    static NSPersistentStoreCoordinator *coord = NULL;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self storageModel]];
        
        NSURL *persistentStoreURL = [self cacheDBAddr];
        
        NSError *pscError = nil;
        if (![coord addPersistentStoreWithType:NSSQLiteStoreType
                                 configuration:nil
                                           URL:persistentStoreURL
                                       options:@{
                                                 NSInferMappingModelAutomaticallyOption: @YES,
                                                 NSMigratePersistentStoresAutomaticallyOption: @YES
                                                 }
                                         error:&pscError]) {
            NSLog(@"Error creating persistent store at %@: %@", persistentStoreURL, [pscError localizedDescription]);
        }
        
    });
    return coord;
}

- (NSManagedObjectContext *)storageContext {
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [CCStorageContextManager persistentStoreCoordinator];
    
    storeWillChangeNotification = [[NSNotificationCenter defaultCenter]
                                   addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                   object:context.persistentStoreCoordinator
                                   queue:[NSOperationQueue mainQueue]
                                   usingBlock:^(NSNotification *note) {
                                       [context performBlock:^{
                                           [context reset];
                                       }];
                                       // drop any managed object references
                                       // disable user interface with setEnabled: or an overlay
                                   }];
    
    storeDidChangeNotification = [[NSNotificationCenter defaultCenter]
                                  addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                  object:context.persistentStoreCoordinator
                                  queue:[NSOperationQueue mainQueue]
                                  usingBlock:^(NSNotification *note) {
                                      // disable user interface with setEnabled: or an overlay
                                      [context performBlock:^{
                                          NSError *saveError;
                                          if (![context save:&saveError]) {
                                              NSLog(@"Save error: %@", saveError);
                                          }
                                          [context reset];
                                          [self startAutosave];
                                      }];
                                      dispatch_semaphore_signal(ubiquiousImported);
                                  }];
    
#if !TARGET_OS_WATCH
    storeDidImport = [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:[CCStorageContextManager persistentStoreCoordinator] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [context performBlock:^{
            [context mergeChangesFromContextDidSaveNotification:note];
            NSError *importSaveErr;
            [context save:&importSaveErr];
            [context reset];
            if (importSaveErr)
                NSLog(@"Import Save Error: %@", importSaveErr);
        }];
    }];
#endif
    
    queue = [NSOperationQueue mainQueue];
    
    return context;
}

- (void)waitForImport {
    dispatch_semaphore_wait(ubiquiousImported, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(ubiquiousImported);
}

- (NSTimer *)autoSave {
    static NSTimer *autosaveTimer = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        autosaveTimer = [NSTimer timerWithTimeInterval:60 target:context selector:@selector(autosave:) userInfo:nil repeats:YES];
    });
    return autosaveTimer;
}

- (void)startAutosave {
    NSTimer *autosaveTimer =  [self autoSave];
    [[NSRunLoop mainRunLoop] addTimer:autosaveTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopAutosave {
    NSTimer *autosaveTimer =  [self autoSave];
    [autosaveTimer invalidate];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self relaseContext];
        }];
#endif
        ubiquiousImported = dispatch_semaphore_create(0);
    }
    return self;
}

- (NSManagedObjectContext *)cacheContext {
    
    cacheCtx = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    cacheCtx.persistentStoreCoordinator = [CCStorageContextManager cacheStoreCoordinator];
    
    return cacheCtx;
}

@end
