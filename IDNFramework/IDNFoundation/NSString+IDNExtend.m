//
//  NSString+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSString+IDNExtend.h"

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

@end
