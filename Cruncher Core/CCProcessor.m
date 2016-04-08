//
//  Processor.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import "CCProcessor.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

dispatch_queue_t processorMessageQueue;
bool CCProcessorType_hasInput(CCProcessorType type) { return type%2; }
bool CCProcessorType_hasOutput(CCProcessorType type) { return type/2; }

@implementation CCProcessorValue
@synthesize defaultValueKey;
@end

@implementation CCOutputPort
@end

#define UIStringUnwrap(x) NSLocalizedString(x, @"")

void alert(NSObject *controller, CCProcessor *senderProcessor) {
#if TARGET_OS_IOS
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:(UIAlertController*)controller animated:true completion:^{}];
#endif
}

void alertUnwrapFail() {
#if TARGET_OS_IOS
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:UIStringUnwrap(@"Unwrap_Failed_Title")
                                                                        message:UIStringUnwrap(@"Unwrap_Failed_Detail") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:UIStringUnwrap(@"Okay") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [controller addAction:action];
    alert(controller, nil);
#endif
}

bool testObject( NSObject * _Nullable obj,Class _Nonnull c) {
    if ([obj isKindOfClass:c]) return true;
    else if ([obj isKindOfClass:[NSArray class]] && [NSArray class] != c) obj = ((NSArray*)obj)[0];
    if ([obj isKindOfClass:[CCProcessorValue class]]) {
        CCProcessorValue *val = (CCProcessorValue*)obj;
        NSObject *defaultObj = [val valueForKeyPath:val.defaultValueKey];
        if ([defaultObj isKindOfClass:c]) return true;
    }
    return false;
}

NSObject *unwrapObject(NSObject * _Nullable obj,Class c) {
    if (obj == nil) return nil;
    if ([obj isKindOfClass:c]) return obj;
    else if ([obj isKindOfClass:[NSArray class]] && [NSArray class] != c && ((NSArray*)obj).count > 0 ) obj = ((NSArray*)obj)[0];
    if ([obj isKindOfClass:[CCProcessorValue class]]) {
        CCProcessorValue *val = (CCProcessorValue*)obj;
        NSObject *defaultObj = [val valueForKeyPath:val.defaultValueKey];
        if ([defaultObj isKindOfClass:c]) return defaultObj;
    }
    alertUnwrapFail();
    return nil;
}

@interface CCProcessor () {
    NSMutableDictionary <NSUUID*, NSMutableSet<NSString*>*> *subscriberList;
    NSMutableSet <CCProcessor*> *dependents;
    NSMutableDictionary <NSUUID *, CCProcessor *>*processorMapping;
    //Cache I/O
    NSDictionary<NSString*, NSObject*>*outputCahce;
    NSMutableDictionary<NSString*, NSObject*> *input;
    
    //Process Depency State
    NSMutableSet *lastUpdatedDependentcy;
    NSMutableDictionary <NSString*, CCOutputPort*>*inputMapping;
    
    UInt8 _input, _output;
    
    //Processor scheduling
    NSTimer *schedulingTimer;
    dispatch_semaphore_t timerSemaphore;
    dispatch_semaphore_t timerEditingSem;
}

- (void)addDependent:(CCProcessor *)processor;
- (void)removeDependent:(CCProcessor *)processor;
- (void)subscribe:(CCProcessor *)sender toProcessorOutput:(NSString *)outputName;
- (void)unsubscribe:(CCProcessor *)sender toProcessorOutput:(NSString *)outputName;
@end

@implementation CCProcessor
@synthesize lastUpdateTime;
@synthesize selfUpdateInterval;
@synthesize processorUUID;

- (UInt8)numberOfInput { return _input; }
- (void)setNumberOfInput:(UInt8)numberOfInput { _input = numberOfInput; }
- (UInt8)numberOfOutput { return _output; }
- (void)setNumberOfOutput:(UInt8)output { _output = output; }

- (void)startProcessWithInput:(NSDictionary <NSString *, NSObject *>*)input complete:(CCProcessorOutputUpdate)completeBlock {
    NSLog(@"This should never be called");
}

+ (void)load {
    processorMessageQueue = dispatch_queue_create("Processor Message Queue", DISPATCH_QUEUE_CONCURRENT);
}

- (NSMutableDictionary <NSString*, CCOutputPort*>*)mapping { return inputMapping; }

- (id)init {
    self = [super init];
    if (self) {
        selfUpdateInterval = -1;
        subscriberList = [NSMutableDictionary new];
        dependents = [NSMutableSet new];
        outputCahce = @{};
        lastUpdatedDependentcy = [NSMutableSet set];
        input = [NSMutableDictionary new];
        processorUUID = [NSUUID UUID];
        processorMapping = [NSMutableDictionary new];
        inputMapping = [NSMutableDictionary new];
        timerSemaphore = dispatch_semaphore_create(1);
        timerEditingSem = dispatch_semaphore_create(1);
        _freshnessTolerance = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        //Only pack what the processor need
        processorUUID = [aDecoder decodeObjectForKey:@"UUID"];
        selfUpdateInterval = [aDecoder decodeDoubleForKey:@"Update Interval"];
        
        //Setup co-processor relationship
        subscriberList = [NSMutableDictionary new];
        dependents = [NSMutableSet new];
        processorMapping = [NSMutableDictionary new];
        inputMapping = [NSMutableDictionary new];
        lastUpdatedDependentcy = [NSMutableSet set];
        
        //Setup Cache
        outputCahce = @{};
        input = [NSMutableDictionary new];
        
        timerSemaphore = dispatch_semaphore_create(1);
        timerEditingSem = dispatch_semaphore_create(1);
        
        [self newUpdateInterval:selfUpdateInterval fromSubscirberProcessor:nil];
    }
    return self;
}

- (void)pauseUpdateTimer:(NSNotification *)notification {
    //if (schedulingTimer)
    //    [schedulingTimer invalidate];
}

- (void)resumeUpdateTimer:(NSNotification *)notification {
    if (schedulingTimer)
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:schedulingTimer forMode:NSDefaultRunLoopMode];
        });
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:processorUUID forKey:@"UUID"];
    [aCoder encodeDouble:selfUpdateInterval forKey:@"Update Interval"];
}

- (void)connectInput:(NSString *)inputName toProcessor:(CCProcessor *)processor forOutput:(NSString *)outputName {
    CCOutputPort *currentConnectPort = inputMapping[inputName];
    if (currentConnectPort)
        //Remove the subscription
        [currentConnectPort.sourceProcessor unsubscribe:self toProcessorOutput:currentConnectPort.outputName];
    CCOutputPort *newOutputPort = [CCOutputPort new];
    newOutputPort.sourceProcessor = processor;
    newOutputPort.outputName = outputName;
    inputMapping[inputName] = newOutputPort;
    [processor subscribe:self toProcessorOutput:outputName];
    //Add dependency
    [self addDependent:processor];
}

- (void)disconnectInput:(NSString *)inputName {
    CCOutputPort *currentConnectPort = inputMapping[inputName];
    if (currentConnectPort)
        //Remove the subscription
        [currentConnectPort.sourceProcessor unsubscribe:self toProcessorOutput:currentConnectPort.outputName];
    inputMapping[inputName] = nil;
    //Remove dependency
    [self removeDependent:currentConnectPort.sourceProcessor];
}

- (void)subscribe:(CCProcessor *)sender toProcessorOutput:(NSString *)outputName {
    NSMutableSet *subscribes = subscriberList[sender.processorUUID];
    if (subscribes == nil) {
        subscriberList[sender.processorUUID] = [NSMutableSet set];
        subscribes = subscriberList[sender.processorUUID];
        processorMapping[sender.processorUUID] = sender;
    }
    [subscribes addObject:outputName];
    
    //Send the last output to the processor
    if (outputCahce[outputName]) [sender updateSubscribedOutput:@{outputName: outputCahce[outputName]} fromProcessor:self];
}

- (void)unsubscribe:(CCProcessor *)sender toProcessorOutput:(NSString *)outputName {
    NSMutableSet *subscribes = subscriberList[sender.processorUUID];
    if (subscribes) [subscribes removeObject:outputName];
    if (subscribes.count == 0) [subscriberList removeObjectForKey:sender.processorUUID];
    
}

- (void)addDependent:(CCProcessor *)processor {
    [dependents addObject:processor];
}

- (void)removeDependent:(CCProcessor *)processor {
    [dependents removeObject:processor];
}

- (void)newUpdateInterval:(NSTimeInterval)refreshInterval fromSubscirberProcessor:(CCProcessor *_Nonnull)proccessor {
    dispatch_semaphore_wait(timerEditingSem, DISPATCH_TIME_FOREVER);
    if (subscriberList.count == 0) {
        //Output node->update interval is not depended on anything
        //The output node with drive the scanning of node
        self.selfUpdateInterval = refreshInterval;
        if (schedulingTimer) {
            [schedulingTimer invalidate];
        }
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(pauseUpdateTimer:)
                                                     name: UIApplicationDidEnterBackgroundNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(resumeUpdateTimer:)
                                                     name: UIApplicationWillEnterForegroundNotification
                                                   object: nil];
#endif
        if (selfUpdateInterval > 0) dispatch_async(dispatch_get_main_queue(), ^{
            self->schedulingTimer = [NSTimer timerWithTimeInterval:selfUpdateInterval target:self selector:@selector(scheduledProcessorRun:) userInfo:nil repeats:YES];
            self->schedulingTimer.tolerance = 5;
            [[NSRunLoop mainRunLoop] addTimer:self->schedulingTimer forMode:NSDefaultRunLoopMode];
        });
    } else {
        //Otherwise, pick nothing
        self.selfUpdateInterval = INFINITY;
    }
    //Loop for everyone
    dispatch_semaphore_signal(timerEditingSem);
}

- (void)actualProcess {
    //Determine "Freshness" of cache2
    if (lastUpdateTime && self.freshnessTolerance >= [lastUpdateTime timeIntervalSinceNow]*-1) {
        //Fresh
        [self updateSubscriber];
    } else {
        //Start all over
        [lastUpdatedDependentcy removeAllObjects];
        //Update input
        if (dependents.count > 0) {
            NSEnumerator *it = dependents.objectEnumerator;
            CCProcessor *processor;
            while ((processor = it.nextObject)) {
                [processor processorStart];
            }
        } else [self dependentFinishUpdate:nil];
    }
    dispatch_semaphore_signal(timerSemaphore);
}

- (void)scheduledProcessorRun:(NSTimer *)timer {
    //Try to lock the sem, which is only possible if it is not running
    NSLog(@"Processor Schedule");
    
    if (dispatch_semaphore_wait(timerSemaphore, DISPATCH_TIME_NOW)) {
        //The process is already running, so reschedule
        dispatch_semaphore_wait(timerEditingSem, DISPATCH_TIME_FOREVER);
        NSLog(@"Schedule Crash");
        schedulingTimer = [NSTimer timerWithTimeInterval:selfUpdateInterval target:self selector:@selector(scheduledProcessorRun:) userInfo:nil repeats:YES];
        schedulingTimer.tolerance = 5;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:schedulingTimer forMode:NSDefaultRunLoopMode];
        });
        dispatch_semaphore_signal(timerEditingSem);
    } else {
        [self actualProcess];
    }
}

- (void)processorStart {
    //Try to lock the sem, which is only possible if it is not running
    //if (dispatch_semaphore_wait(timerSemaphore, DISPATCH_TIME_NOW)) {
        //The process is already running
    //} else {
        //If the process is not running, reschedule the timer
//        dispatch_semaphore_wait(timerEditingSem, DISPATCH_TIME_FOREVER);
//        if (schedulingTimer) {
//            [schedulingTimer invalidate];
//        }
//        if (selfUpdateInterval > 0) { schedulingTimer = [NSTimer timerWithTimeInterval:selfUpdateInterval target:self selector:@selector(scheduledProcessorRun:) userInfo:nil repeats:YES];
//            schedulingTimer.tolerance = 5;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[NSRunLoop mainRunLoop] addTimer:schedulingTimer forMode:NSDefaultRunLoopMode];
//            });
//        }
//        dispatch_semaphore_signal(timerEditingSem);
        [self actualProcess];
    //}
}

- (NSDictionary *)outputTransformation:(NSDictionary *)inputDict {
    return inputDict;
}

- (void)updateSubscriber {
    NSEnumerator *it = subscriberList.keyEnumerator;
    NSUUID *_processorUUID;
    while ((_processorUUID = it.nextObject)) {
        dispatch_async(processorMessageQueue, ^{
            //Reconstruct dictionary
            NSMutableDictionary *results = [NSMutableDictionary new];
            
            NSEnumerator *it = subscriberList[_processorUUID].objectEnumerator;
            NSString *key;
            while ((key = it.nextObject)) {
                if (key && outputCahce[key])
                    [results setObject:outputCahce[key] forKey:key];
            }
            
            
            if (results.allKeys.count > 0) {
                CCProcessor *processor = processorMapping[_processorUUID];
                [processor updateSubscribedOutput:results fromProcessor:self];
                [processor dependentFinishUpdate:self];
            }
        });
    }
    
    [self.delegate processorHasFinishUpdate:self];
}

- (void)updateResult:(NSDictionary<NSString *,NSObject *> *)result {
    
    NSString *err = (NSString *)[result valueForKey:@"Error"];
    if (err) {
#if TARGET_OS_iOS
        UIAlertController *con = [UIAlertController alertControllerWithTitle:UIStringUnwrap(@"ProcessorError") message:UIStringUnwrap(err) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
        [con addAction:action];
        alert(con, self);
#endif
        return;
    }
    
    outputCahce = [self outputTransformation:result];
    lastUpdateTime = [NSDate date];
    
    [self updateSubscriber];
    
    //Update Timer
//    dispatch_semaphore_wait(timerEditingSem, DISPATCH_TIME_FOREVER);
//    if (schedulingTimer) {
//        [schedulingTimer invalidate];
//    }
//    if (selfUpdateInterval > 0) { schedulingTimer = [NSTimer timerWithTimeInterval:selfUpdateInterval target:self selector:@selector(scheduledProcessorRun:) userInfo:nil repeats:YES];
//        schedulingTimer.tolerance = 5;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSRunLoop mainRunLoop] addTimer:schedulingTimer forMode:NSDefaultRunLoopMode];
//        });
//    }
//    dispatch_semaphore_signal(timerEditingSem);
}

- (void)updateSubscribedOutput:(NSDictionary <NSString*, NSObject*> *)outputValue fromProcessor:(CCProcessor *)processor {
    for (NSString *key in inputMapping) {
        CCOutputPort *port = inputMapping[key];
        if (port.sourceProcessor == processor) {
            id value = outputValue[port.outputName];
            if (value) {
                [input setObject:value forKey:key];
            }
        }
    }
}

- (void)dependentFinishUpdate:(CCProcessor *)processor {
    if (processor) [lastUpdatedDependentcy addObject:processor];
    if ([lastUpdatedDependentcy isEqualToSet:dependents]) {
        [self startProcessWithInput:[NSDictionary dictionaryWithDictionary:input] complete:^(NSDictionary<NSString *,NSObject *> *_result) {
            //Drain the inputs
            [input removeAllObjects];
            dispatch_async(processorMessageQueue, ^{
                [self updateResult:_result];
            });
        }];
    }
}

- (NSDictionary *)rawOutput {
    return outputCahce;
}

@end
