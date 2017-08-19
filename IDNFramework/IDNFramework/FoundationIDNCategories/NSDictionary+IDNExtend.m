//
//  NSDictionary+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSDictionary+IDNExtend.h"
#import "NSString+IDNExtend.h"

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

- (NSString*)urlParamsString
{
	NSMutableString *string = [NSMutableString string];
	for (NSString *key in self)
	{
		NSObject *value = [self valueForKey:key];
		if([value isKindOfClass:[NSString class]])
			[string appendFormat:@"%@=%@&", [key urlEncoding], [((NSString*)value) urlEncoding]];
		else
			[string appendFormat:@"%@=%@&", [key urlEncoding], value];
	}

	if([string length] > 0)
		[string deleteCharactersInRange:NSMakeRange([string length] - 1, 1)];

	return string;
}

#pragma mark - dic <==> json

- (NSString *)jsonString
{
	NSError *error = nil;
	NSData * data = [NSJSONSerialization dataWithJSONObject:self
													options:0
													  error:&error];
	if(error)
	{
		NSLog(@"%s: convert to json string FAILED!\nDictionary: %@\nError: %@", __func__, self, error);
		return nil;
	}

	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)jsonData
{
	NSError *error = nil;
	NSData * data = [NSJSONSerialization dataWithJSONObject:self
													options:0
													  error:&error];
	if(error)
	{
		NSLog(@"%s: convert to json data FAILED!\nDictionary: %@\nError: %@", __func__, self, error);
		return nil;
	}

	return data;
}

+ (NSDictionary*)dictionaryWithJSONData:(NSData*)jsonData error:(NSError**)error
{
	NSError* innerError = nil;
	NSDictionary *dicResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&innerError];
	if(innerError)
	{
		NSLog(@"%s: convert json data to dictionary FAILED!\nJsonData: %@\nError: %@", __func__, [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] truncateWithLength:1024], innerError);
		if(error)
			*error = innerError;
		return nil;
	}
	if(error)
		*error = nil; //没有错误
	return [dicResponse dictionaryWithoutNSNull];
}

@end
