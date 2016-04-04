//
//  CCXMLSource.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import "CCXMLParser.h"

@interface CCXMLNode ()
- (instancetype)initWithNode:(CCXMLNode *)parent tag:(NSString *)tag attributeDict:(NSDictionary<NSString *,NSString *> *)attr;
@end

@implementation CCXMLNode : NSObject
@synthesize parentNode, tagName, attributeDict;
- (instancetype)initWithNode:(CCXMLNode *)parent tag:(NSString *)tag attributeDict:(NSDictionary<NSString *,NSString *> *)attr {
    self = [super init];
    if (self) {
        parentNode = parent;    tagName = tag;  attributeDict = attr;
    }
    return self;
}
@end

@interface CCXMLSource () <NSXMLParserDelegate> {
    NSXMLParser *praser;
    CCProcessorOutputUpdate callback;
    CCXMLNode *currentNode;
    NSMutableArray *nodes;
    NSMutableString *values;
}
@property (readonly, atomic) NSMutableDictionary<NSString*, NSPredicate*> *parsingPredicate;
@end

@implementation CCXMLSource
@synthesize parsingPredicate;

- (instancetype)init {
    self = [super init];
    if (self) {
        parsingPredicate = [NSMutableDictionary new];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.parsingCondition = [aDecoder decodeObjectForKey:@"XMLSource-ParsingCondition"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.parsingCondition forKey:@"XMLSource-ParsingCondition"];
}

- (void)setParsingCondition:(NSDictionary<NSString *,NSString *> *)parsingCondition {
    NSMutableSet <NSString*>*oldKeys = [NSMutableSet setWithArray:_parsingCondition.allKeys];
    NSArray *newKeys = [NSArray arrayWithArray:parsingCondition.allKeys];
    for (NSString *newKey in newKeys) {
        NSString *oldValue = _parsingCondition[newKey];
        NSString *newValue = parsingCondition[newKey];
        bool refresh = false;
        if (oldValue == NULL||![oldValue isEqualToString:newValue])
            refresh = true;
        if (refresh) {
            NSPredicate *newPredicate = [NSPredicate predicateWithFormat:newValue];
            parsingPredicate[newKey] = newPredicate;
        }
        [oldKeys removeObject:newKey];
    }
    [parsingPredicate removeObjectsForKeys:oldKeys.allObjects];
    _parsingCondition = parsingCondition;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    nodes = [NSMutableArray new];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    values = [NSMutableString string];
    CCXMLNode *node = [[CCXMLNode alloc] initWithNode:currentNode tag:elementName attributeDict:attributeDict];
    [nodes addObject:node];
    currentNode = node;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [values appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    currentNode.value = [NSString stringWithString:values];
    currentNode = currentNode.parentNode;
    NSLog(@"%@: %@", elementName, values);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"%@", parseError);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSMutableDictionary <NSString*, NSString*>*output = [NSMutableDictionary new];
    [parsingPredicate enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString * _Nonnull key, NSPredicate * _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray *filteredObj = [nodes filteredArrayUsingPredicate:obj];
        if (filteredObj.count > 0)
            output[key] = filteredObj[0];
    }];
    //Cleanup
    [nodes removeAllObjects];
    callback(output);
}

- (NSData *)processXHTML:(NSData *)data {
    NSString *_string = [NSString stringWithUTF8String:data.bytes];
    //Flatten the data
    //_string = [_string stringByReplacingOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, _string.length)];
    //_string = [_string stringByReplacingOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, _string.length)];
    //Remove Javascript
    _string = [_string stringByReplacingOccurrencesOfString:@"<script(.|\n)*?</script>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _string.length)];
    _string = [_string stringByReplacingOccurrencesOfString:@"<script(.|\n)*?/>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _string.length)];
    //Remove comments
    _string = [_string stringByReplacingOccurrencesOfString:@"<!--.*?-->" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _string.length)];
    //Replace & Symbol
    _string = [_string stringByReplacingOccurrencesOfString:@"&" withString:@"&lt;" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, _string.length)];
    
    _string = [_string stringByReplacingOccurrencesOfString:@"<meta http-equiv=\"X-UA-Compatible\".*?>" withString:@""];
    
    return [_string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)startProcessWithInput:(NSDictionary<NSString *,NSObject *> *)input complete:(CCProcessorOutputUpdate)completeBlock {
    callback = completeBlock;
    currentNode = nil;
    
    NSData *data = (NSData *)input[@"Data"];
    
    data = [self processXHTML:data];
    
    praser = [[NSXMLParser alloc] initWithData:data];
    praser.delegate = self;
    [praser parse];
}

@end
