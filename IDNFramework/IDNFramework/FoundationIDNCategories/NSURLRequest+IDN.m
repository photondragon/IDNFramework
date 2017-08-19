//
//  NSURLRequest+IDN.m
//  IDNFramework
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "NSURLRequest+IDN.h"

@implementation NSURLRequest(IDN)

+ (instancetype)requestWithURLString:(NSString *)URLString
{
	return [self requestWithURL:[NSURL URLWithString:URLString]];
}

@end
