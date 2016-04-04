//
//  Bucket+CoreDataProperties.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/21/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Bucket.h"

NS_ASSUME_NONNULL_BEGIN

@interface Bucket (CoreDataProperties)

@property (nullable, nonatomic, retain) NSData *confData;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<Data *> *data;

@end

@interface Bucket (CoreDataGeneratedAccessors)

- (void)insertObject:(Data *)value inDataAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDataAtIndex:(NSUInteger)idx;
- (void)insertData:(NSArray<Data *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDataAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDataAtIndex:(NSUInteger)idx withObject:(Data *)value;
- (void)replaceDataAtIndexes:(NSIndexSet *)indexes withData:(NSArray<Data *> *)values;
- (void)addDataObject:(Data *)value;
- (void)removeDataObject:(Data *)value;
- (void)addData:(NSOrderedSet<Data *> *)values;
- (void)removeData:(NSOrderedSet<Data *> *)values;

@end

NS_ASSUME_NONNULL_END
