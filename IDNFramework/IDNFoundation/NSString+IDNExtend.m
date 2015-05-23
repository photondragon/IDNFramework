//
//  NSString+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSString+IDNExtend.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(IDNExtend)

+ (NSString*)documentsPath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths firstObject];
}

+ (NSString*)documentsPathWithFileName:(NSString*)fileName
{
	if(fileName.length==0)
		return nil;
	return [NSString stringWithFormat:@"%@/%@", [self documentsPath], fileName];
}

#pragma mark hash

- (NSString *)md5
{
	const char *cStr = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end
