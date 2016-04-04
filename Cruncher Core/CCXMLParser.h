//
//  CCXMLSource.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <CruncherCore/CCProcessor.h>
#elif TARGET_OS_WATCH
#import <CruncherCore/CCProcessor.h>
#elif TARGET_OS_MAC
#import <CruncherCore/CCProcessor.h>
#endif

@interface CCXMLNode : NSObject
@property (readonly) CCXMLNode *parentNode;
@property (readonly) NSString *tagName;
@property (readonly) NSDictionary<NSString *,NSString *> *attributeDict;
@property (readwrite) NSString *value;
@end

@interface CCXMLSource : CCProcessor <NSCoding>

@property (readwrite, nonatomic) NSDictionary<NSString *, NSString *>*parsingCondition;
@end
