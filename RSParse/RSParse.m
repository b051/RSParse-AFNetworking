//
//  RSParse.m
//  RSParse
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Rex.S Lab. All rights reserved.
//

#import "RSParse.h"
#import "AFJSONRequestOperation.h"

NSString * const kParseWhereKey = @"where";
NSString * const kParseOrderKey = @"order";
NSString * const kParseSkipKey = @"skip";
NSString * const kParseIncludeKey = @"include";
NSString * const kParseLimitKey = @"limit";

@interface AFJSONRequestOperation ()

- (void)setJSONError:(NSError *)JSONError;
- (NSError *)JSONError;

@end

@interface PFJSONRequestOperation : AFJSONRequestOperation
@property (readwrite, nonatomic, strong) id responseJSON;
@end

@implementation PFJSONRequestOperation

@synthesize responseJSON = _responseJSON;

+ (NSDateFormatter *)formatter
{
	NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *formatter = dictionary[@"iso"];
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		dictionary[@"iso"] = formatter;
	}
	return formatter;
}

+ (void)decodeDateFromDictionary:(NSMutableDictionary *)param
{
	if ([param isKindOfClass:[NSDictionary class]]) {
		[[param copy] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([obj isKindOfClass:[NSDictionary class]]) {
				if ([obj[@"__type"] isEqualToString:@"Date"]) {
					NSDateFormatter *formatter = [[self class] formatter];
					param[key] = [formatter dateFromString:obj[@"iso"]];
				}
			} else if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"updatedAt"]) {
				NSDateFormatter *formatter = [[self class] formatter];
				param[key] = [formatter dateFromString:obj];
			}
		}];
	}
}

+ (void)encodeDateFromDictionary:(NSMutableDictionary *)param
{
	[[param copy] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if ([obj isKindOfClass:[NSDictionary class]]) {
			NSMutableDictionary *_obj = [obj mutableCopy];
			[self encodeDateFromDictionary:_obj];
			param[key] = _obj;
		} else if ([obj isKindOfClass:[NSDate class]]) {
			if ([key isEqualToString:@"updatedAt"] || [key isEqualToString:@"createdAt"]) {
				param[key] = [[PFJSONRequestOperation formatter] stringFromDate:obj];
			} else {
				param[key] = @{@"__type" : @"Date", @"iso": [[PFJSONRequestOperation formatter] stringFromDate:obj]};
			}
		} else if ([obj isKindOfClass:[NSArray class]]) {
			NSMutableArray *_a = [obj mutableCopy];
			[obj enumerateObjectsUsingBlock:^(id o, NSUInteger idx, BOOL *stop) {
				if ([o isKindOfClass:[NSMutableDictionary class]]) {
					[self encodeDateFromDictionary:0];
				} else if ([o isKindOfClass:[NSDictionary class]]) {
					NSMutableDictionary *_d = [o mutableCopy];
					[self encodeDateFromDictionary:_d];
					_a[idx] = _d;
				}
			}];
			param[key] = _a;
		}
	}];
}

+ (NSString *)JSONStringFromObject:(id)parameters
{
	if ([parameters isKindOfClass:[NSMutableDictionary class]]) {
		[self encodeDateFromDictionary:parameters];
	} else if ([parameters isKindOfClass:[NSDictionary class]]) {
		NSMutableDictionary *_parameters = [parameters mutableCopy];
		[self encodeDateFromDictionary:_parameters];
		parameters = _parameters;
	} else if ([parameters isKindOfClass:[NSArray class]]) {
		NSMutableArray *_a = [parameters mutableCopy];
		[[_a copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj isKindOfClass:[NSMutableDictionary class]]) {
				[self encodeDateFromDictionary:obj];
			} else if ([obj isKindOfClass:[NSDictionary class]]) {
				NSMutableDictionary *_d = [obj mutableCopy];
				[self encodeDateFromDictionary:_d];
				_a[idx] = _d;
			}
		}];
		parameters = _a;
	} else {
		return [parameters description];
	}
	NSError *error = nil;
	NSData *JSONData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];;
	if (!error) {
		NSString *jsonString = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
		return jsonString;
	}
	return @"";
}

- (id)responseJSON
{
	if (!_responseJSON && [self.responseData length] > 0 && [self isFinished] && !self.JSONError) {
        if ([self.responseData length] == 0) {
            return nil;
        }
		NSError *error = nil;
		NSMutableDictionary *JSON = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];
		if (error) {
			self.JSONError = error;
			return nil;
		}
		id _error = JSON[@"error"];
		if (_error) {
			self.JSONError = [NSError errorWithDomain:@"com.parse"
												 code:[JSON[@"code"] intValue]
											 userInfo:@{
							NSLocalizedDescriptionKey: NSLocalizedString(_error, nil),
										NSURLErrorKey: [[self request] URL]
							  }];
			return nil;
		}
		
		id objects = JSON[@"results"];
		if (objects) {
			[objects enumerateObjectsUsingBlock:^(NSMutableDictionary *object, NSUInteger idx, BOOL *stop) {
				[[self class] decodeDateFromDictionary:object];
			}];
			self.responseJSON = objects;
		} else {
			[[self class] decodeDateFromDictionary:JSON];
			self.responseJSON = JSON;
		}
	}
	return _responseJSON;
}

@end

@interface RSParse ()

@property (readwrite, nonatomic) NSMutableDictionary *defaultHeaders;

@end

@implementation RSParse
{
	dispatch_queue_t delete_queue;
	dispatch_queue_t saving_queue;
}

+ (RSParse *)shared
{
	static RSParse *client;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		client = [[RSParse alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.parse.com/1/"]];
		[client setDefaultHeader:@"Accept" value:@"application/json"];
		[client setDefaultHeader:@"X-Parse-Application-Id" value:Parse_Application_Id];
#ifdef Parse_Master_Id
		[client setDefaultHeader:@"X-Parse-Master-Key" value:Parse_Master_Id];
#else
		[client setDefaultHeader:@"X-Parse-REST-API-Key" value:Parse_REST_API_Id];
#endif
		[PFJSONRequestOperation addAcceptableStatusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(400, 15)]];
		[client registerHTTPOperationClass:[PFJSONRequestOperation class]];
		[client setParameterEncoding:AFJSONParameterEncoding];
		client.operationQueue.maxConcurrentOperationCount = 4;
		client->delete_queue = dispatch_queue_create("com.rexsheng.RSParse.delete_queue", DISPATCH_QUEUE_CONCURRENT);
		client->saving_queue = dispatch_queue_create("com.rexsheng.RSParse.saving_queue", DISPATCH_QUEUE_CONCURRENT);
	});
	return client;
}

static NSString * AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAFCharactersToBeEscaped = @":/.?&=;+!@#$()~,";
    static NSString * const kAFCharactersToLeaveUnescaped = @"[]";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAFCharactersToLeaveUnescaped, (__bridge CFStringRef)kAFCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
	NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
	
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
			
			NSMutableString *query = [NSMutableString stringWithString:[path rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&"];
			[parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[query appendString:key];
				[query appendString:@"="];
				NSString *jsonString = [[PFJSONRequestOperation JSONStringFromObject:obj] stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
				jsonString = AFPercentEscapedQueryStringPairMemberFromStringWithEncoding(jsonString, NSUTF8StringEncoding);
				[query appendString:jsonString];
				[query appendString:@"&"];
			}];
			[query deleteCharactersInRange:NSMakeRange(query.length - 1, 1)];
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingString:query]];
            [request setURL:url];
        } else {
			[request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
			[request setHTTPBody:[[PFJSONRequestOperation JSONStringFromObject:parameters] dataUsingEncoding:self.stringEncoding]];
        }
    }
	return request;
}

+ (void)classes:(NSString *)className where:(NSDictionary *)cond include:(NSString *)include eachBatch:(void(^)(NSArray *objects, dispatch_group_t group))eachBatch completion:(dispatch_block_t)completion
{
	NSUInteger count = 100;
	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group);
	NSDate *now = [NSDate date];
	NSMutableDictionary *_cond = [@{@"updatedAt": @{@"$lt": now}} mutableCopy];
	[_cond addEntriesFromDictionary:cond];
	
	void(^__block batch)(NSUInteger skip) = ^(NSUInteger skip) {
		[RSParse classes:className where:_cond limit:count skip:skip order:@"updatedAt" include:include completion:^(NSArray *objects, NSError *error) {
			@autoreleasepool {
				if (!error) {
					dispatch_group_t _g = dispatch_group_create();
					if (eachBatch) {
						eachBatch(objects, _g);
					}
					dispatch_group_notify(_g, dispatch_get_current_queue(), ^{
						if (objects.count == count) {
							batch(skip + count);
						} else {
							dispatch_group_leave(group);
						}
					});
				} else {
					NSLog(@"error %@", error);
					dispatch_group_leave(group);
				}
			}
		}];
	};
	batch(0);
	dispatch_group_notify(group, dispatch_get_main_queue(), ^{
		//		NSLog(@"%@ matching %@ are iterated", className, _cond);
		if (completion) completion();
	});
}

+ (void)classes:(NSString *)className eachBatch:(void(^)(NSArray *objects, dispatch_group_t group))eachBatch completion:(dispatch_block_t)completion
{
	[self classes:className where:nil include:nil eachBatch:eachBatch completion:completion];
}

+ (void)classes:(NSString *)name where:(NSDictionary *)where limit:(NSUInteger)limit skip:(NSUInteger)skip order:(NSString *)order include:(NSString *)include completion:(getobjects_block_t)completion
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	if (where) parameters[kParseWhereKey] = where;
	if (skip) parameters[kParseSkipKey] = @( skip );
	if (order) parameters[kParseOrderKey] = order;
	if (limit != 100) parameters[kParseLimitKey] = @( limit );
	if (include) parameters[kParseIncludeKey] = include;
	[self.shared getPath:[NSString stringWithFormat:@"classes/%@", name] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (completion) completion(responseObject, nil);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (completion) completion(nil, error);
	}];
}

+ (void)classes:(NSString *)name where:(NSDictionary *)where limit:(NSUInteger)limit skip:(NSUInteger)skip completion:(getobjects_block_t)completion
{
	[self classes:name where:where limit:limit skip:skip order:nil include:nil completion:completion];
}

+ (void)classes:(NSString *)name where:(NSDictionary *)where completion:(getobjects_block_t)completion
{
	[self classes:name where:where limit:100 skip:0 completion:completion];
}

+ (void)delete:(NSString *)className objectIds:(NSArray *)objectIds completionBlock:(void (^)(NSArray *operations))completionBlock
{
	NSMutableArray *mutableOperations = [NSMutableArray arrayWithCapacity:objectIds.count];
	for (NSString *objectId in objectIds) {
		@autoreleasepool {
			NSString *path = [NSString stringWithFormat:@"classes/%@/%@", className, objectId];
			NSURLRequest *request = [self.shared requestWithMethod:@"DELETE" path:path parameters:nil];
			AFHTTPRequestOperation *operation = [self.shared HTTPRequestOperationWithRequest:request success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				NSLog(@"delete error %@", error);
			}];
			operation.successCallbackQueue = self.shared->delete_queue;
			[mutableOperations addObject:operation];
		}
	}
    [self.shared enqueueBatchOfHTTPRequestOperations:mutableOperations progressBlock:nil completionBlock:completionBlock];
}

+ (void)function:(NSString *)function parameters:(NSDictionary *)parameters completionBlock:(dispatch_block_t)completionBlock
{
	NSString *path = [NSString stringWithFormat:@"functions/%@", function];
	[self.shared postPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (completionBlock) completionBlock();
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"function error %@", error);
		if (completionBlock) completionBlock();
	}];
}

+ (void)saveAll:(NSString *)className objects:(NSArray *)objects completionBlock:(void (^)(NSArray *saved))completionBlock
{
	NSMutableArray *mutableOperations = [NSMutableArray arrayWithCapacity:objects.count];
	NSString *path = [NSString stringWithFormat:@"classes/%@", className];
	NSMutableArray *saved = [NSMutableArray array];
	for (NSDictionary *object in objects) {
		NSString *objectId = object[@"objectId"];
		NSURLRequest *request;
		if (objectId) {
			[saved addObject:object];
			NSMutableDictionary *_object = [object mutableCopy];
			[_object removeObjectForKey:@"objectId"];
			request = [self.shared requestWithMethod:@"PUT" path:[path stringByAppendingPathComponent:objectId] parameters:_object];
		} else {
			request = [self.shared requestWithMethod:@"POST" path:path parameters:object];
		}
		AFHTTPRequestOperation *operation = [self.shared HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
			if (responseObject[@"objectId"]) {
				[saved addObject:responseObject];
			}
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"save error %@", error);
		}];
		operation.successCallbackQueue = self.shared->saving_queue;
        [mutableOperations addObject:operation];
	}
    [self.shared enqueueBatchOfHTTPRequestOperations:mutableOperations progressBlock:nil completionBlock:^(NSArray *operations) {
		if (completionBlock) (completionBlock(saved));
	}];
}

+ (NSDictionary *)pointerToClass:(NSString *)name objectId:(NSString *)objectId
{
	return @{@"__type": @"Pointer", @"className": name, @"objectId": objectId};
}

@end
