//
//  CCStorageBucket+CCStorageBucket_Priv.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import "CCStorageBucket.h"
#import "Bucket+CoreDataProperties.h"

@interface CCStorageBucket (CCStorageBucket_Priv)
- (instancetype)initWithBucket:(Bucket *)b;
- (Bucket *)obj;
- (NSData *)confData;
@end
