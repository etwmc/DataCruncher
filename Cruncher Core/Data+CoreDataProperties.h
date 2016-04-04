//
//  Data+CoreDataProperties.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 12/21/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Data.h"

NS_ASSUME_NONNULL_BEGIN

@interface Data (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *insertDate;
@property (nullable, nonatomic, retain) NSData *value;

@end

NS_ASSUME_NONNULL_END
