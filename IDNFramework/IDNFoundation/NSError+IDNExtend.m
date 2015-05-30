//
//  NSError+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSError+IDNExtend.h"

@implementation NSError(IDNExtend)

+ (instancetype)errorDescription:(NSString*)description
{
	return [self errorWithDomain:nil description:description];
}

+ (instancetype)errorWithDomain:(NSString *)domain description:(NSString*)description
{
	if(domain.length==0)
		domain = @"NSErrorDomainGeneric";
	NSDictionary* errorInfo;
	if(description.length)
		errorInfo = @{NSLocalizedDescriptionKey:description};
	else
		errorInfo = nil;
	return [NSError errorWithDomain:domain code:0 userInfo:errorInfo];
}

@end
