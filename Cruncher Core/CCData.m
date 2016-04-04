//
//  CCData.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import "CCData.h"
#import "CCData_Priv.h"

@interface CCData () {
}
@end

@implementation CCData
@synthesize obj;

- (instancetype)init:(Data *)data {
    self = [super init];
    if (self)
        obj = data;
    return self;
}

- (NSObject *)defaultObject {
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:obj.value options:0 error:&error];
    if (!error && dictionary && dictionary.count) {
        return dictionary.allValues.firstObject;
    } else return nil;
}

- (id)valueForUndefinedKey:(NSString *)key {
    return [obj valueForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [obj setValue:value forKey:key];
}

@end
