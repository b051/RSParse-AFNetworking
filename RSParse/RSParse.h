//
//  RSParse.h
//  RSParse
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Rex.S Lab. All rights reserved.
//

#import "AFHTTPClient.h"

typedef void(^getobjects_block_t) (NSArray *objects, NSError *error);

@interface RSParse : AFHTTPClient

+ (void)classes:(NSString *)name where:(NSDictionary *)where limit:(NSUInteger)limit skip:(NSUInteger)skip order:(NSString *)order include:(NSString *)include completion:(getobjects_block_t)completion;
+ (void)classes:(NSString *)name where:(NSDictionary *)where limit:(NSUInteger)limit skip:(NSUInteger)skip completion:(getobjects_block_t)completion;
+ (void)classes:(NSString *)name where:(NSDictionary *)where completion:(getobjects_block_t)completion;
+ (void)classes:(NSString *)className where:(NSDictionary *)cond include:(NSString *)include eachBatch:(void(^)(NSArray *objects, dispatch_group_t group))eachBatch completion:(dispatch_block_t)completion;

+ (void)delete:(NSString *)className objectIds:(NSArray *)objectIds completionBlock:(void (^)(NSArray *operations))completionBlock;

+ (void)saveAll:(NSString *)className objects:(NSArray *)objects completionBlock:(void (^)(NSArray *saved))completionBlock;

+ (NSDictionary *)pointerToClass:(NSString *)name objectId:(NSString *)objectId;

+ (void)function:(NSString *)function parameters:(NSDictionary *)parameters completionBlock:(dispatch_block_t)completionBlock;

+ (RSParse *)shared;

@end
