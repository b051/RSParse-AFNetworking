//
//  RSParseUser.h
//  RSParse
//
//  Created by Rex Sheng on 10/28/12.
//  Copyright (c) 2012 Rex.S Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSParseUser : NSObject

+ (NSDictionary *)currentUser;

+ (void)createOrLoginUser:(NSString *) username email:(NSString *)email password:(NSString *)password completion:(void(^)(BOOL))completion;

+ (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password completion:(void(^)(BOOL))completion;
+ (void)loginUser:(NSString *)username password:(NSString *)password completion:(void(^)(BOOL))completion;
+ (void)requestPasswordReset:(NSString *)email completion:(void(^)(BOOL))completion;

@end
