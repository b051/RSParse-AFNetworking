//
//  RSParseRole.m
//  RSParse
//
//  Created by Rex Sheng on 10/28/12.
//  Copyright (c) 2012 Rex.S Lab. All rights reserved.
//

#import "RSParseRole.h"
#import "RSParse.h"
#import "RSParseUser.h"

@implementation RSParseRole

+ (void)createAdministrators
{
	//	[self.shared getPath:@"roles" parameters:@{@"where": @{@"name": @"Administrators"}} success:^(AFHTTPRequestOperation *operation, NSArray *responseObject) {
	//		if (!responseObject.count) {
	////
	//			self.shared postPath:@"roles" parameters:@{@"name": @"Administrators", @"ACL": @{@"*": @{@"read" : @YES}}} success:<#^(AFHTTPRequestOperation *operation, id responseObject)success#> failure:<#^(AFHTTPRequestOperation *operation, NSError *error)failure#>
	//		}
	//	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	//
	//	}];
	[RSParse.shared getPath:@"roles/PfyhrBd0CU" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		
	}];
}
@end
