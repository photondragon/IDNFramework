//
//  NSArray+IDN.m
//  IDNFramework
//
//  Created by photondragon on 15/7/21.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSArray+IDN.h"

@implementation NSArray(IDN)

- (NSString*)inplode
{
	NSMutableString* str = [NSMutableString new];
	BOOL isFirst = YES;
	for (id obj in self) {
		if(isFirst)
		{
			[str appendFormat:@"%@", obj];
			isFirst = NO;
		}
		else
			[str appendFormat:@",%@", obj];
	}
	return [str copy];
}

@end
