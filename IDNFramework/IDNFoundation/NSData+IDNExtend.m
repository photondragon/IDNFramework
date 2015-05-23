//
//  NSData+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSData+IDNExtend.h"
#import "NSString+IDNExtend.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData(IDNExtend)

- (BOOL)writeToDocumentFile:(NSString *)file
{
	NSString* documentsDir = [NSString documentsPath];
	if ([file rangeOfString:@"/"].location != NSNotFound)//包含子目录
	{
		NSString* dir = [file stringByDeletingLastPathComponent];
		NSString* dirFullPath = [NSString stringWithFormat:@"%@/%@", documentsDir, dir];
		if([[NSFileManager defaultManager] fileExistsAtPath:dirFullPath]==NO)//目录不存在
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:dirFullPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	NSString* fullPath = [NSString stringWithFormat:@"%@/%@", documentsDir, file];
	return [self writeToFile:fullPath atomically:YES];
}

#pragma mark hash

- (NSString*)md5
{
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5( self.bytes, (CC_LONG)self.length, result );
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3],
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end
