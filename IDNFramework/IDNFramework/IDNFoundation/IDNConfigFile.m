//
//  IDNConfigFile.m
//  IDNFramework
//
//  Created by photondragon on 15/8/19.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNConfigFile.h"
#import "IDNNetFileUpdater.h"
#import "NSString+IDNExtend.h"
#import "NSDictionary+IDNExtend.h"

static NSMutableDictionary* cfgDicts = nil;
static NSMutableDictionary* cfgPaths = nil;

@implementation IDNConfigFile

+ (void)initialize
{
	if(self == [IDNConfigFile self])
	{
		NSString* configDir = [NSString libraryPathWithFileName:@"IDNConfigFile"];
		[configDir mkdir];
	}
}

+ (NSMutableDictionary*)cfgDicts
{
	if(cfgDicts==nil)
	{
		@synchronized(self)
		{
			if(cfgDicts==nil)
				cfgDicts = [NSMutableDictionary new];
		}
	}
	return cfgDicts;
}
+ (NSMutableDictionary*)cfgPaths
{
	if(cfgPaths==nil)
	{
		@synchronized(self)
		{
			if(cfgPaths==nil)
				cfgPaths = [NSMutableDictionary new];
		}
	}
	return cfgPaths;
}

+ (void)registerWithUrl:(NSString*)cfgUrl refreshInterval:(NSTimeInterval)refreshInterval forceRefreshOnLaunch:(BOOL)forceRefreshOnLaunch defaultJsonFile:(NSString*)defaultJsonFile
{
	NSString* className = NSStringFromClass(self);
	NSString* persistPath = [NSString libraryPathWithFileName:[NSString stringWithFormat:@"IDNConfigFile/%@.cfg", NSStringFromClass(self)]];
	if([self cfgPaths][className])//已经注册过
		return;
	
	[self cfgPaths][className] = persistPath;
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:persistPath];
	if(dict==nil)
	{
		if(defaultJsonFile.length)
		{
			if([defaultJsonFile rangeOfString:@"/"].location==0) //绝对路径
			{
				dict = [NSDictionary dictionaryWithContentsOfFile:defaultJsonFile];
			}
			else //相对MainBundle路径
			{
				NSString* path = [[NSBundle mainBundle] pathForResource:defaultJsonFile ofType:nil];
				NSData* data = [NSData dataWithContentsOfFile:path];
				if(data.length>0)
				{
					id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
					dict = [(NSDictionary*)obj dictionaryWithoutNSNull];
				}
			}
		}
		if(dict==nil)
			dict = [NSDictionary new];
	}
	[self cfgDicts][className] = dict;
	
	if(cfgUrl.length)
	{
		__weak __typeof(self) wself = self;
		[[IDNNetFileUpdater sharedInstance] registerUrl:cfgUrl updateInterval:refreshInterval forceUpdateOnLaunch:forceRefreshOnLaunch updatedCallback:^(NSData *data) {
			__typeof(self) sself = wself;
			[sself manualRefreshWithData:data];
		}];
	}
}

+ (NSDictionary*)configDict
{
	NSString* className = NSStringFromClass(self);
	return [self cfgDicts][className];
}

+ (void)manualRefreshWithJsonFile:(NSString*)jsonFilePath
{
	[self manualRefreshWithData:[NSData dataWithContentsOfFile:jsonFilePath]];
}
+ (void)manualRefreshWithJsonString:(NSString*)jsonString
{
	[self manualRefreshWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
}
+ (void)manualRefreshWithData:(NSData*)data
{
	if(data==nil)
		return;
	id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	NSDictionary* dict = [(NSDictionary*)obj dictionaryWithoutNSNull];
	[self manualRefreshWithDictionary:dict];
}
+ (void)manualRefreshWithDictionary:(NSDictionary*)dicConfig
{
	if(dicConfig==nil)
		return;
	NSString* className = NSStringFromClass(self);
	[self cfgDicts][className] = dicConfig;
	[self configRefreshed];
	
	NSString* persistPath = [self cfgPaths][className];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[dicConfig writeToFile:persistPath atomically:YES];
	});
}

+ (void)configRefreshed
{
	
}

@end
