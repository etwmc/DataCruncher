//
//  CCNetworkSource.m
//  Data Crunchers
//
//  Created by Wai Man Chan on 14/10/2015.
//
//

#import "CCNetworkSource.h"

#import <Foundation/Foundation.h>

@interface CCNetworkSource () <NSURLSessionDelegate, NSURLSessionDataDelegate> {
    NSURLSession *session;
    CCDataFetchSuccess _success;
    CCDataFetchFail _failed;
    NSURLSessionDataTask *task;
    NSMutableData *_data;
    
    NSTimer *recoveryTimer;
}
@end

@implementation CCNetworkSource
@synthesize url;

+ (NSURLSessionConfiguration *)backgroundConf {
    static NSURLSessionConfiguration *conf = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.WMC.CCNetworkSource"];
        conf.requestCachePolicy = NSURLCacheStorageAllowed;
#if TARGET_OS_MAC
#elif
        conf.sessionSendsLaunchEvents = YES;
#endif
        conf.discretionary = YES;
        conf.timeoutIntervalForResource = 5;
    });
    return conf;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        session = [NSURLSession sessionWithConfiguration:[CCNetworkSource backgroundConf] delegate:self delegateQueue:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    url = [decoder decodeObjectForKey:@"NetworkSource-URL"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [super encodeWithCoder:encoder];
    [encoder encodeObject:url forKey:@"NetworkSource-URL"];
}

- (instancetype)initWithURL:(NSURL *)sourceURL {
    self = [super init];
    if (self) {
        url = sourceURL;
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error && _failed) _failed(error);
    else if (_success) _success(_data);
    if (error) {
        recoveryTimer = [NSTimer timerWithTimeInterval:15 target:self selector:@selector(start:) userInfo:nil repeats:false];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSRunLoop mainRunLoop] addTimer:recoveryTimer forMode:NSDefaultRunLoopMode];
        });
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)start:(NSTimer *)timer {
    recoveryTimer = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/601.5.17 (KHTML, like Gecko) Version/9.1 Safari/601.5.17" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"max-age=0" forHTTPHeaderField:@"Cache-Control"];
    [request setValue:[url absoluteString] forHTTPHeaderField:@"Referer"];
    [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    task = [session dataTaskWithRequest:request];
    _data = [NSMutableData new];
    [task resume];
}

- (void)fetchData:(CCDataFetchSuccess)successBlock errorBlock:(CCDataFetchFail)failedBlock {
    if (!session) session = [NSURLSession sessionWithConfiguration:[CCNetworkSource backgroundConf] delegate:self delegateQueue:nil];
    _failed = failedBlock;
    _success = successBlock;
    [self start: nil];
}

- (BOOL)canRunInBackground { return YES; }

@end
