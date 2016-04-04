//
//  Storage+CoreDataProperties.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/21/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Storage.h"

NS_ASSUME_NONNULL_BEGIN

@interface Storage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSData *confData;
@property (nullable, nonatomic, retain) NSNumber *type;
@property (nullable, nonatomic, retain) NSSet<Bucket *> *bucket;

@end

@interface Storage (CoreDataGeneratedAccessors)

- (void)addBucketObject:(Bucket *)value;
- (void)removeBucketObject:(Bucket *)value;
- (void)addBucket:(NSSet<Bucket *> *)values;
- (void)removeBucket:(NSSet<Bucket *> *)values;

@end

NS_ASSUME_NONNULL_END
