//
//  NSURL+IDN.m
//  xiangyue3
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import "NSURL+IDN.h"
#import "NSDictionary+IDNExtend.h"

@implementation NSURL(IDN)

+ (instancetype)URLWithString:(NSString *)URLString params:(NSDictionary*)params
{
	if(params.count>0)
		URLString = [NSString stringWithFormat:@"%@?%@", URLString, [params urlParamsString]];
	return [self URLWithString:URLString];
}

@end
