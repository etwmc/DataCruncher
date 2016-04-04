//
//  Processor.h
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import <Foundation/Foundation.h>

extern dispatch_queue_t _Nonnull processorMessageQueue;

@interface CCProcessorValue : NSObject
@property (readwrite, nonnull) NSString * defaultValueKey;
@end

@class CCProcessor;

//Feed forward
@protocol CCProcessorSubscribeProtocol <NSObject>
- (void)updateSubscribedOutput:(NSDictionary <NSString*, NSObject*> * _Nonnull)outputValue fromProcessor:(CCProcessor *_Nonnull)processor;
//Call whenever the process determine the cache is good enough, or the process has just finish update its output
- (void)dependentFinishUpdate:(CCProcessor *_Nullable)processor;
@end

@protocol CCProcessorUpdateProtocol <NSObject>
//Schedule route update
- (void)newUpdateInterval:(NSTimeInterval)refreshInterval fromSubscirberProcessor:(CCProcessor *_Nonnull)proccessor;
//Manual update
- (void)processorStart;
@end

@protocol CCProcessorConnectionProtocol <NSObject>
- (void)connectInput:(NSString * _Nonnull)inputName toProcessor:(CCProcessor * _Nonnull)processor forOutput:(NSString * _Nonnull)outputName;
- (void)disconnectInput:(NSString * _Nonnull)inputName;
@end

@protocol CCProcessorDelegate <NSObject>
- (void)processorHasFinishUpdate:(CCProcessor *_Nonnull)processor;
@end

typedef void(^CCProcessorOutputUpdate)(NSDictionary <NSString*,NSObject*>*_Nonnull);

typedef enum : NSUInteger {
    None = 0,
    Input = 1,
    Output = 2,
    Intermediate = 3
} CCProcessorType;
bool CCProcessorType_hasInput(CCProcessorType type);
bool CCProcessorType_hasOutput(CCProcessorType type);

bool testObject( NSObject * _Nullable ,Class _Nonnull);
NSObject *_Nullable unwrapObject( NSObject * _Nullable ,Class _Nonnull);

@interface CCOutputPort: NSObject
@property (readwrite) CCProcessor * _Nonnull sourceProcessor;
@property (readwrite) NSString * _Nonnull outputName;
@end

@interface CCProcessor : NSObject <CCProcessorUpdateProtocol, CCProcessorSubscribeProtocol, CCProcessorConnectionProtocol, NSCoding>
@property (readonly, nullable) NSDate *lastUpdateTime;
@property (readonly) NSTimeInterval freshnessTolerance;
//For intermediate processor, this value means "freshness"
//Determine whether the processor should refresh again, or just give the cache data
@property (readwrite) NSTimeInterval selfUpdateInterval;
//Co-processors relationship
@property (readonly) CCProcessorType type;
@property (readwrite) NSObject <CCProcessorDelegate> * _Nullable delegate;
@property (readonly) NSUUID * _Nonnull processorUUID;
- (instancetype _Nonnull)initWithCoder:(NSCoder * _Nonnull)decoder;
- (void)encodeWithCoder:(NSCoder * _Nonnull)encoder;
- (NSDictionary <NSString*, CCOutputPort*>* _Nonnull)mapping;
- (UInt8)numberOfInput;
- (void)setNumberOfInput:(UInt8)input;
- (UInt8)numberOfOutput;
- (void)setNumberOfOutput:(UInt8)output;
//Processor Behavior
- (instancetype _Nonnull)init;
//Processor Subclass Behavior
- (void)startProcessWithInput:(NSDictionary <NSString *, NSObject *>* _Nonnull)input complete:(CCProcessorOutputUpdate _Nonnull)completeBlock;
- (NSDictionary * _Nonnull)outputTransformation:(NSDictionary * _Nonnull)inputDict;
- (NSDictionary<NSString*, NSObject*>* _Nullable)rawOutput;
- (void)actualProcess;
@end