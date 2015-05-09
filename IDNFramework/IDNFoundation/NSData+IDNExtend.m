//
//  NSData+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSData+IDNExtend.h"
#import "NSString+IDNExtend.h"

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

@end
