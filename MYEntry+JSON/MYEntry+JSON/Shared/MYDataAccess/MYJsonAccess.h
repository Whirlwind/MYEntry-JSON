//
//  MYJsonAccess.h
//  foodiet
//
//  Created by Whirlwind James on 11-12-27.
//  Copyright (c) 2011年 BOOHEE. All rights reserved.
//
#import "ASICacheDelegate.h"

@class ASIHTTPRequest;

@interface MYJsonAccess : NSObject

@property (copy, nonatomic) NSString *serverDomain;
@property (copy, nonatomic) NSString *nameSpace;
@property (copy, nonatomic) NSString *apiVersion;

@property (copy, nonatomic) NSString *securityKey;
@property (assign, nonatomic) NSInteger cachePolicy;

@property (copy, nonatomic) NSString *downloadDestinationPath;

@property (readonly, nonatomic) NSArray *errors;
@property (readonly, nonatomic) NSError *lastError;

@property (assign) unsigned long long bytesDownloadedSoFar;


@property (copy, nonatomic) void(^progressChangedBlock)(long long totalSize, long long downloadedSize);

- (NSString *)parseAPI:(NSString *)api method:(NSString **)method args:(NSMutableDictionary **)args;
- (void)handleParams:(NSMutableDictionary **)params;

- (NSDictionary *)requestAPI:(NSString *)api;
- (NSDictionary *)requestAPI:(NSString *)api
                   postValue:(NSDictionary *)values;
- (NSDictionary *)requestURLString:(NSString *)url
             postValue:(NSDictionary *)values;
- (NSDictionary *)requestURLString:(NSString *)url
                            method:(NSString *)method;
- (NSDictionary *)requestURLString:(NSString *)url
                         postValue:(NSDictionary *)value
                            method:(NSString *)method;
- (void)cancelRequest;
- (BOOL)requestIsCancelled;

- (NSString *)api:(NSString *)api;

+ (NSString *)api:(NSString *)api;
+ (NSString *)api:(NSString *)api withServerDomain:(NSString *)serverDomain nameSpace:(NSString *)nameSpace version:(NSString *)version;
+ (NSString *)serverDomain;
+ (NSString *)apiVersion;
+ (id)requestBaseAPIUrl:(NSString *)url postValue:(NSDictionary *)value;
+ (id)requestAPI:(NSString *)api;
+ (id)requestAPI:(NSString *)api errors:(NSArray **)errors;
+ (id)requestAPI:(NSString *)api postValue:(NSDictionary *)values;
+ (id)requestAPI:(NSString *)api postValue:(NSDictionary *)values errors:(NSArray **)errors;

+ (id)useSecurityKey:(NSString *)key;
@end
