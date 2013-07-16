//
//  MYJsonAccess.m
//  foodiet
//
//  Created by Whirlwind James on 11-12-27.
//  Copyright (c) 2011年 BOOHEE. All rights reserved.
//

#import "MYJsonAccess.h"
#import "ASIFormDataRequest.h"
#import "NSJSONSerialization+JSONKit.h"
#import "ASIHTTPRequest+MYSign.h"
#import "URLHelper.h"
#import "UIDevice+MACAddress.h"
#import "ASIDownloadCache.h"
#import "MYFileStream.h"

@interface MYJsonAccess ()

@property (nonatomic, strong) ASIHTTPRequest *request;
@property (strong, nonatomic) NSArray *errors;

@end

@implementation MYJsonAccess

+ (void)initialize {
    [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    [super initialize];
}
#pragma mark - init
- (id)init {
    if (self = [super init]) {
        self.cachePolicy = ASIUseDefaultCachePolicy;
    }
    return self;
}
#pragma mark - getter
- (NSString *)serverDomain {
    if (_serverDomain == nil) {
        _serverDomain = [[self class] serverDomain];
    }
    return _serverDomain;
}

- (NSString *)nameSpace {
    if (_nameSpace == nil) {
        _nameSpace = [[self class] nameSpace];
    }
    return _nameSpace;
}

- (NSString *)apiVersion {
    if (_apiVersion == nil) {
        _apiVersion = [[self class] apiVersion];
    }
    return _apiVersion;
}

#pragma mark - request
- (void)cancelRequest{
    [self.request cancel];
}

- (BOOL)requestIsCancelled{
    return [self.request isCancelled];
}

#pragma mark - request api
- (NSString *)parseAPI:(NSString *)api method:(NSString **)method args:(NSMutableDictionary **)args{
    NSArray *array = [api componentsSeparatedByString:@"@"];
    if ([array count] < 2) {
        *method = @"GET";
        return api;
    } else {
        *method = array[0];
        return array[1];
    }
}

- (void)handleParams:(NSMutableDictionary **)params {
    [*params setValue:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleName"] forKey:@"app_name"];

    NSString *mac = [[UIDevice currentDevice] macAddress];
    if (mac) {
        [*params setValue:mac forKey:@"mac"];
    }

    NSString *ver = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    if (ver)
        [*params setValue:ver forKey:@"app_ver" ];

    NSString *build = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    if (build)
        [*params setValue:build forKey:@"app_build"];

//    [*params addEntriesFromDictionary:@{@"treatment_type": @"face"}];
}

- (void)pickFileStreamFromDictionary:(NSMutableDictionary *)dic to:(NSMutableDictionary *)result withPath:(NSString *)path {
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[MYFileStream class]]) {
            [result setValue:obj forKey:path == nil || [path isKindOfClass:[NSString class]] ? key : [NSString stringWithFormat:@"%@[%@]", path, key]];
            [dic removeObjectForKey:key];
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            [self pickFileStreamFromDictionary:obj to:result withPath:path == nil || [path isKindOfClass:[NSString class]] ? key : [NSString stringWithFormat:@"%@[%@]", path, key]];
            if ([obj count] == 0) {
                [dic removeObjectForKey:key];
            }
        } else {
        }
    }];
}

- (id)requestBaseAPIUrl:(NSString *)url postValue:(NSDictionary *)values {
    NSMutableDictionary *newValues = values == nil ? [NSMutableDictionary dictionaryWithCapacity:1] : [NSMutableDictionary dictionaryWithDictionary:values];
    [self handleParams:&newValues];
    NSString *method = nil;
    url = [self parseAPI:url method:&method args:&newValues];
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:1];
    [self pickFileStreamFromDictionary:newValues to:result withPath:nil];
    if ([newValues count] > 0) {
        [result setValue:[newValues universalConvertToJSONString] forKey:@"data"];
    }
    return [self requestURLString:url postValue:result method:method requestHeaders:@{@"data-type" : @"json"} security:YES];
}

- (id)requestAPI:(NSString *)api {
    return [self requestAPI:api postValue:nil];
}

- (id)requestAPI:(NSString *)api postValue:(NSDictionary *)values {
    NSString *method = nil;
    NSMutableDictionary *v = values == nil ? nil : [[NSMutableDictionary alloc] initWithDictionary:values];
    NSString *url = [self parseAPI:api method:&method args:&v];
    return [self requestBaseAPIUrl:[NSString stringWithFormat:@"%@@%@", method, [self api:url]]
                         postValue:v];
}

#pragma mark - request url
- (void)buildRequest:(NSString *)url method:(NSString *)requestMethod params:(NSDictionary *)postValue requestHeaders:(NSDictionary *)headers {
    if ([requestMethod isEqualToString:@"POST"]) {
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
        [postValue enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[MYFileStream class]]) {
                MYFileStream *fileStream = (MYFileStream *)obj;
                [request addData:fileStream.data withFileName:fileStream.fileName andContentType:fileStream.mimeType forKey:key];
            } else {
                [request addPostValue:obj forKey:key];
            }
        }];
        self.request = request;
    } else {
        self.request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[URLHelper _queryStringWithBase:url parameters:postValue]]];
        postValue = nil;
    }
    self.request.requestMethod = requestMethod;
    if (![requestMethod isEqualToString:@"GET"]) {
        [self.request setShouldAttemptPersistentConnection:NO];
    }
    self.request.cachePolicy = self.cachePolicy;
    if (headers) {
        if (self.request.requestHeaders) {
            [self.request.requestHeaders addEntriesFromDictionary:headers];
        } else {
            self.request.requestHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
        }
    }
}

- (NSDictionary *)requestURLString:(NSString *)url postValue:(NSDictionary *)values {
    return [self requestURLString:url postValue:values method:@"POST"];
}

- (NSDictionary *)requestURLString:(NSString *)url method:(NSString *)method {
    return [self requestURLString:url postValue:nil method:method];
}

- (NSDictionary *)requestURLString:(NSString *)url postValue:(NSDictionary *)values method:(NSString *)method {
    return [self requestURLString:url postValue:values method:method requestHeaders:nil];
}

- (NSDictionary *)requestURLString:(NSString *)url postValue:(NSDictionary *)values method:(NSString *)method requestHeaders:(NSDictionary *)headers {
    return [self requestURLString:url postValue:values method:method requestHeaders:headers security:NO];
}

- (NSDictionary *)requestURLString:(NSString *)url postValue:(NSDictionary *)values method:(NSString *)method requestHeaders:(NSDictionary *)headers security:(BOOL)security {
    self.errors = nil;
    [self buildRequest:url method:method params:values requestHeaders:headers];
    if (security && self.securityKey) {
        [self.request buildSecurityParams:self.securityKey postData:values addIDParams:NO];
    }
    if (self.downloadDestinationPath) {
        [self.request setDownloadDestinationPath:self.downloadDestinationPath];
        if (self.progressChangedBlock) {
            [self.request setDownloadProgressDelegate:self];
            [self.request incrementDownloadSizeBy:100*1024];
        }
    }
    [self.request setShouldCompressRequestBody:YES];
    LogInfo(@"------BEGIN REQUEST %@: %@", method, url);
    [self.request startSynchronous];
    LogInfo(@"------END REQUEST %@: %@", method, url);
    if ([self.request isCancelled]) return nil;
    NSDictionary *dic = [[self.request responseString] universalConvertToJSONObject];
    int s = [self.request responseStatusCode];
    if (self.downloadDestinationPath && !(s < 300 && s >= 200)) {
        dic = [[NSData dataWithContentsOfFile:self.downloadDestinationPath] universalConvertToJSONObject];
        [[NSFileManager defaultManager] removeItemAtPath:self.downloadDestinationPath error:NULL];
    }
    NSArray *errors = dic[@"errors"];
    NSDictionary *error = dic[@"error"];
    if (errors == nil && error) {
        errors = @[error];
    }
    if (errors) {
        if ([error isKindOfClass:[NSNull class]]) {
            [self reportErrors:@[@{@"code": @"-1", @"message": @"未知错误！"}]
                           url:url
                        method:method
                        status:s
                       request:values
                      response:[self.request responseString]];
        } else {
            [self reportErrors:errors
                           url:url
                        method:method
                        status:s
                       request:values
                      response:[self.request responseString]];
        }
        return nil;
    }
    if (s >= 200 && s < 300) {
        if (dic == nil) {
            [self reportErrors:@[@{@"code": @"-1", @"message": @"接收到的数据无法解析！"}]
                           url:url
                        method:method
                        status:s
                       request:values
                      response:[self.request responseString]];
            return nil;
        }
        LogInfo(@"URL: %@ %@ REQUEST: %@ RESPONSE: %@", method, url, values, dic);
        return dic;
    } else {
        if (s == 0) {
            [self reportErrors:@[@{@"code": @"-1", @"message": @"网络连接存在异常!"}]
                           url:url
                        method:method
                        status:s
                       request:values
                      response:nil];
        } else {
            [self reportErrors:@[@{@"code": @"-1", @"message": @"未知错误！"}]
                           url:url
                        method:method
                        status:s
                       request:values
                      response:[self.request responseString]];
        }
    }
    return nil;
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    if (self.progressChangedBlock) {
        self.progressChangedBlock(request.contentLength, bytes);
    }
}
#pragma mark - error
- (NSError *)lastError {
    if (self.errors && [self.errors count] > 0) {
        return [self.errors lastObject];
    }
    return nil;
}

- (void)reportErrors:(NSArray *)errors
                 url:(NSString *)url
              method:(NSString *)method
              status:(NSInteger)status
             request:(NSDictionary *)request
            response:(NSString *)response {
    if (status == 0) {
        LogError(@"URL: %@ %@ STATE: %d MESSAGE: %@", method, url, status, @"网络连接存在异常");
    } else {
        LogError(@"URL: %@ %@ STATE: %d REQUEST: %@ RESPONSE: %@", method, url, status, request, response);
    }
    NSMutableArray *es = [[NSMutableArray alloc] initWithCapacity:[errors count]];
    for (NSDictionary *e in errors) {
        [es addObject:[NSError errorWithDomain:@"json" code:[e[@"code"] integerValue] userInfo:@{NSLocalizedDescriptionKey: e[@"message"]}]];
    }
    self.errors = es;
}

#pragma mark - override
- (NSString *)api:(NSString *)api {
    return [[self class] api:api withServerDomain:self.serverDomain nameSpace:self.nameSpace version:self.apiVersion];
}

+ (NSString *)api:(NSString *)api withServerDomain:(NSString *)serverDomain nameSpace:(NSString *)nameSpace version:(NSString *)version {
    return [NSString stringWithFormat:@"%@%@%@%@", serverDomain, nameSpace, version, api];
}

+ (NSString *)api:(NSString *)api {
    return [self api:api withServerDomain:[self serverDomain] nameSpace:[self nameSpace] version:[self apiVersion]];
}
#pragma mark - public class methods
+ (NSString *)serverDomain {
    return nil;
}
+ (NSString *)nameSpace {
    return @"";
}
+ (NSString *)apiVersion {
    return @"";
}
+ (id)requestBaseAPIUrl:(NSString *)url postValue:(NSDictionary *)value {
    MYJsonAccess *json = [[[self class] alloc] init];
    NSDictionary *dic = [json requestBaseAPIUrl:url postValue:value];
    return dic;
}

+ (id)requestAPI:(NSString *)api {
    return [self requestAPI:api errors:nil];
}

+ (id)requestAPI:(NSString *)api errors:(NSArray **)errors {
    MYJsonAccess *json = [[[self class] alloc] init];
    NSDictionary *dic = [json requestAPI:api];
    if (errors) {
        *errors = json.errors;
    }
    return dic;
}

+ (id)requestAPI:(NSString *)api postValue:(NSDictionary *)values {
    return [self requestAPI:api postValue:values errors:nil];
}

+ (id)requestAPI:(NSString *)api postValue:(NSDictionary *)values errors:(NSArray **)errors {
    MYJsonAccess *json = [[[self class] alloc] init];
    NSDictionary *dic = [json requestAPI:api
                                postValue:values
                         ];
    if (errors) {
        *errors = json.errors;
    }
    return dic;
}

+ (id)useSecurityKey:(NSString *)key {
    MYJsonAccess *json = [[[self class] alloc] init];
    [json setSecurityKey:key];
    return json;
}
@end
