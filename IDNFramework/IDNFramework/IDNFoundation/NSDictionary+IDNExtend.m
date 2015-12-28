//
//  NSDictionary+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSDictionary+IDNExtend.h"

@implementation NSDictionary(IDNExtend)

+ (NSArray*)arrayWithoutNSNull:(NSArray*)array
{
	if(array==nil)
		return nil;
	NSMutableArray* arr = [NSMutableArray array];
	for (id obj in array) {
		if([obj isKindOfClass:[NSNull class]])
			continue;
		else if ([obj isKindOfClass:[NSDictionary class]])
			[arr addObject:[self dictionaryWithoutNSNull:obj]];
		else if([obj isKindOfClass:[NSArray class]])
			[arr addObject:[self arrayWithoutNSNull:obj]];
		else
			[arr addObject:obj];
	}
	return arr;
}

+ (NSDictionary*)dictionaryWithoutNSNull:(NSDictionary*)dictionary
{
	if(dictionary==nil)
		return nil;
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	for (id key in dictionary) {
		id value = dictionary[key];
		if([value isKindOfClass:[NSNull class]])
			continue;
		else if([value isKindOfClass:[NSArray class]])
			dic[key] = [self arrayWithoutNSNull:value];
		else if([value isKindOfClass:[NSDictionary class]])
			dic[key] = [self dictionaryWithoutNSNull:value];
		else
			dic[key] = value;
	}
	return dic;
}

- (NSDictionary*)dictionaryWithoutNSNull
{
	return [self.class dictionaryWithoutNSNull:self];
}

- (NSString *)jsonString
{
	NSError *error = nil;
	NSData * data = [NSJSONSerialization dataWithJSONObject:self
													options:0
													  error:&error];
	if(error)
		NSLog(@"JSON Parsing Error: %@", error);
	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
