//
//  NSObject+IDNModel.m
//  IDNFramework
//
//  Created by photondragon on 16/5/28.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "NSObject+IDNModel.h"
#import "NSObject+IDN.h"

@implementation NSObject(IDNModel)

+ (NSArray*)fieldNames
{
	return @[];
}
+ (NSDictionary*)fieldTypes
{
	return @{};
}

+ (instancetype)modelWithFieldValues:(NSDictionary*)fieldValues
{
	id model = [[self alloc] init];
	[model loadFieldValues:fieldValues];
	return model;
}

- (void)loadFieldValues:(NSDictionary*)fieldValues
{
	// 如果keyValues不是字典
	if([fieldValues isKindOfClass:[NSDictionary class]]==NO)
		return;

	@try{
		NSArray* fieldNames = [self.class fieldNames];
		for (NSString*key in fieldValues) {
			if(key.length==0)
				continue;
			if([fieldNames containsObject:key]==NO)
				continue;
			id value = fieldValues[key];
			if(value == [NSNull null]) //相当于nil
				continue;
			[self setValue:value forKey:key];
		}
	}@catch(NSException *exception){
		NSLog(@"设置属性值失败: %@", exception.description);
	}
	@try{
		NSNumber* cacheTime = fieldValues[@"_cacheTime"];
		if([cacheTime isKindOfNSNumber])
			[self setValue:cacheTime forKey:@"_cacheTime"];
	}@catch(NSException *exception){
	}
}

- (NSDictionary*)getFieldValues
{
	NSArray* fieldNames = [self.class fieldNames];

	NSMutableDictionary* fieldValues = [NSMutableDictionary new];
	@try {
		for (NSString* key in fieldNames) {
			if(key.length==0)
				continue;
			id value = [self valueForKey:key];
			fieldValues[key] = value;
		}
	} @catch (NSException *exception) {
		NSLog(@"提取属性值失败: %@", exception.description);
	}
	@try {
		id value = [self valueForKey:@"_cacheTime"];
		if(value && [value isKindOfNSNumber])
			fieldValues[@"_cacheTime"] = value;
	} @catch (NSException *exception) {
	}
	return [fieldValues copy];
}

@end
