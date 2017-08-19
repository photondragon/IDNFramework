//
//  NSObject+IDN.m
//  xiangyue3
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import "NSObject+IDN.h"

@implementation NSObject(IDN)

- (BOOL)isKindOfNSNull
{
	return [self isKindOfClass:[NSNull class]];
}
- (BOOL)isKindOfNSError
{
	return [self isKindOfClass:[NSError class]];
}
- (BOOL)isKindOfNSString
{
	return [self isKindOfClass:[NSString class]];
}
- (BOOL)isKindOfNSNumber
{
	return [self isKindOfClass:[NSNumber class]];
}
- (BOOL)isKindOfNSArray
{
	return [self isKindOfClass:[NSArray class]];
}
- (BOOL)isKindOfNSDictionary
{
	return [self isKindOfClass:[NSDictionary class]];
}
- (BOOL)isMemberOfNSError
{
	return [self isMemberOfClass:[NSError class]];
}
- (BOOL)isMemberOfNSString
{
	return [self isMemberOfClass:[NSString class]];
}
- (BOOL)isMemberOfNSNumber
{
	return [self isMemberOfClass:[NSNumber class]];
}
- (BOOL)isMemberOfNSArray
{
	return [self isMemberOfClass:[NSArray class]];
}
- (BOOL)isMemberOfNSDictionary
{
	return [self isMemberOfClass:[NSDictionary class]];
}

@end
