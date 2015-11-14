//
//  NSFileManager+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/19.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSFileManager+IDNExtend.h"
#import "NSString+IDNExtend.h"

@implementation NSFileManager(IDNExtend)

+ (BOOL)removeDocumentFile:(NSString *)filePath
{
	if(filePath.length==0)
		return NO;
	NSString* oldPath = [NSString documentsPathWithFileName:filePath];
	return [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
}

@end
