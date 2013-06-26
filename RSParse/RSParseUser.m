//
//  RSParseUser.m
//  RSParse
//
//  Created by Rex Sheng on 10/28/12.
//  Copyright (c) 2012 Rex.S Lab. All rights reserved.
//

#import "RSParseUser.h"
#import "RSParse.h"

@implementation RSParseUser

static NSString *userObjectId;

+ (void)setCurrentUser:(id)user
{
	userObjectId = user[@"objectId"];
	NSLog(@"user.objectId = %@", userObjectId);
	NSString *sessionToken = user[@"sessionToken"];
	NSAssert(sessionToken != nil, @"Missing sessionToken");
	[RSParse.shared setDefaultHeader:@"X-Parse-Session-Token" value:sessionToken];
}

+ (NSDictionary *)currentUser
{
	if (userObjectId)
		return [RSParse pointerToClass:@"_User" objectId:userObjectId];
	return nil;
}

+ (void)createOrLoginUser:(NSString *) username email:(NSString *)email password:(NSString *)password completion:(void(^)(BOOL))completion
{
	[self createUser:username email:email password:password completion:^(BOOL created) {
		if (!created) {
			[self loginUser:username password:password completion:^(BOOL loggedin) {
				if (!loggedin) {
					[self requestPasswordReset:email completion:completion];
				} else {
					if (completion) completion(YES);
				}
			}];
		} else {
			if (completion) completion(YES);
		}
	}];
}

+ (void)createUser:(NSString *)username email:(NSString *)email password:(NSString *)password completion:(void(^)(BOOL))completion
{
	[RSParse.shared postPath:@"users" parameters:@{
	 @"username": username,
	 @"email": email,
	 @"password": password} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		 [self setCurrentUser:responseObject];
		 if (completion) completion(YES);
	 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		 if (completion) completion(NO);
	 }];
}

+ (void)requestPasswordReset:(NSString *)email completion:(void(^)(BOOL))completion
{
	[RSParse.shared postPath:@"requestPasswordReset" parameters:@{@"email": email} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (completion) completion(YES);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (completion) completion(NO);
	}];
}

+ (void)loginUser:(NSString *)username password:(NSString *)password completion:(void(^)(BOOL))completion
{
	[RSParse.shared getPath:@"login" parameters:@{
	 @"username": username,
	 @"password": password} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		 [self setCurrentUser:responseObject];
		 if (completion) completion(YES);
	 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		 NSLog(@"error %@", error);
		 if (completion) completion(NO);
	 }];
}
@end
