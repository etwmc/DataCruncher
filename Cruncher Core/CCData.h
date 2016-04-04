//
//  CCData.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import <Foundation/Foundation.h>
@class Data;
@interface CCData : NSObject
- (instancetype)init:(Data *)data;
- (NSObject *)defaultObject;
@property (readonly) Data *obj;
@end
