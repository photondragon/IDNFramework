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

@interface IDNConfigInfo : NSObject
@property(nonatomic,strong) NSDictionary* configuration;
@property(nonatomic,strong) NSString* cfgFileUrl;
@property(nonatomic,strong) NSString* persistPath;
@property(nonatomic,strong) NSString* defaultCfgFile;
@property(nonatomic) NSTimeInterval refreshInterval;
@property(nonatomic) BOOL refreshImmediately;
@property(nonatomic,strong) NSString* env;
@property(nonatomic) BOOL autoRefresh; //是否已提交自动更新
@end
@implementation IDNConfigInfo
- (instancetype)initWithCfgFileUrl:(NSString*)cfgUrl
					   persistPath:(NSString*)persistPath
					defaultCfgFile:(NSString*)defaultCfgFile
				   refreshInterval:(NSTimeInterval)refreshInterval
				refreshImmediately:(BOOL)refreshImmediately
							   env:(NSString*)env
{
	self = [super init];
	if (self) {
		NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:persistPath];
		if(dict==nil)
		{
			if(defaultCfgFile.length)
			{
				if([defaultCfgFile rangeOfString:@"/"].location==0) //绝对路径
				{
					dict = [NSDictionary dictionaryWithContentsOfFile:defaultCfgFile];
				}
				else //MainBundle中的路径
				{
					NSString* path = [[NSBundle mainBundle] pathForResource:defaultCfgFile ofType:nil];
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
		_configuration = dict;
		_cfgFileUrl = cfgUrl;
		_persistPath = persistPath;
		_defaultCfgFile = defaultCfgFile;
		_refreshInterval = refreshInterval;
		_refreshImmediately = refreshImmediately;
		_env = env;
	}
	return self;
}

@end

static NSString* currentEnv = nil;

@implementation IDNConfigFile

// 不能实例化IDNConfigFile类及其子类
- (instancetype)init
{
	return nil;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
	return nil;
}

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* configDir = [NSString libraryPathWithFileName:@"IDNConfigFile"];
		[configDir mkdir];
	});
}

+ (NSMutableDictionary*)dicConfigs
{
	static NSMutableDictionary* dicConfigs;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{dicConfigs = [NSMutableDictionary new];});
	return dicConfigs;
}

+ (NSString*)getCurrentClassNameFromMethod:(const char*)method
{
	NSString* className = NSStringFromClass(self);
	if([className isEqualToString:@"IDNConfigFile"])
		@throw [NSString stringWithFormat:@"不能通过IDNConfigFile类调用%s方法，只能通过IDNConfigFile类的某个子类调用这个方法（请参数IDNConfigFile.h中的说明）", method];
	return className;
}
+ (void)setupWithUrl:(NSString*)cfgUrl refreshInterval:(NSTimeInterval)refreshInterval forceRefreshOnLaunch:(BOOL)forceRefreshOnLaunch defaultJsonFile:(NSString*)defaultJsonFile forEnv:(NSString *)env
{
	env = [env copy];
	if(env==nil || [env isKindOfNSNull])
		env = @"";
	NSString* envDir = [env md5];
	NSString* className = [self getCurrentClassNameFromMethod:__func__];
	NSString* dir = [NSString libraryPathWithFileName:[NSString stringWithFormat:@"IDNConfigFile/env_%@", envDir]];
	[dir mkdir];
	NSString* persistPath = [NSString stringWithFormat:@"%@/%@.cfg", dir, className];

	NSMutableDictionary* dicConfigs = [self dicConfigs];
	NSMutableDictionary* dicConfigsInEnv = dicConfigs[env];
	if(dicConfigsInEnv[className])//已经注册过
		return;

	if(dicConfigsInEnv==nil)
	{
		dicConfigsInEnv = [NSMutableDictionary new];
		dicConfigs[env] = dicConfigsInEnv;
	}

	IDNConfigInfo* info;
	info = [[IDNConfigInfo alloc] initWithCfgFileUrl:cfgUrl
									  persistPath:persistPath
								   defaultCfgFile:defaultJsonFile
								  refreshInterval:refreshInterval
							   refreshImmediately:forceRefreshOnLaunch
											  env:env];
	dicConfigsInEnv[className] = info;

	if(currentEnv==nil)
		currentEnv = @"";

	if([currentEnv isEqualToString:env])
		[self startAutoUpdateWithInfo:info forEnv:env];
}

+ (void)startAutoUpdateWithInfo:(IDNConfigInfo*)info forEnv:(NSString*)env
{
	if(info.cfgFileUrl.length==0)
		return;

	__weak __typeof(self) wself = self;
	[[IDNNetFileUpdater sharedInstance] registerUrl:info.cfgFileUrl updateInterval:info.refreshInterval forceUpdateOnLaunch:info.refreshImmediately updatedCallback:^(NSData *data) {
		__typeof(self) sself = wself;
		if([currentEnv isEqualToString:env]) //如果环境改变了
			[sself manualRefreshWithData:data];
	}];
}

+ (NSString*)currentEnv
{
	return currentEnv;
}

+ (void)switchToEnv:(NSString *)env
{
	env = [env copy];
	if(env==nil || [env isKindOfNSNull])
		env = @"";
	
	if([currentEnv isEqualToString:env])
		return;

	// 取消旧环境的配置文件的自动更新
	id oldEnvKey = currentEnv;
	if(oldEnvKey){
		NSMutableDictionary* dicConfigsInOldEnv = [self dicConfigs][oldEnvKey];
		for (NSString* className in dicConfigsInOldEnv.allKeys) {
			IDNConfigInfo* info = dicConfigsInOldEnv[className];
			if(info.cfgFileUrl.length)
				[[IDNNetFileUpdater sharedInstance] unregisterUrl:info.cfgFileUrl];
		}
	}

	currentEnv = env;

	// 设置新环境下的配置文件的自动更新
	NSMutableDictionary* dicConfigsInEnv = [self dicConfigs][env];
	for (NSString* className in dicConfigsInEnv.allKeys) {
		IDNConfigInfo* info = dicConfigsInEnv[className];
		[NSClassFromString(className) startAutoUpdateWithInfo:info forEnv:env];
	}
}

+ (NSArray*)allEnvs
{
	return [[self dicConfigs] allKeys];
}

+ (IDNConfigInfo*)configInfo
{
	id env = currentEnv;
	if(env==nil)
		return nil;
	NSString* className = [self getCurrentClassNameFromMethod:__func__];
	IDNConfigInfo* info = [self dicConfigs][env][className];
	return info;
}
+ (NSDictionary*)configuration
{
	return [self configInfo].configuration;
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
	dicConfig = [dicConfig copy];
	NSString* className = [self getCurrentClassNameFromMethod:__func__];
	IDNConfigInfo* info = [self dicConfigs][currentEnv][className];
	if(info==nil) //没有配置过当前类在当前环境下的配置文件
		return;
	info.configuration = dicConfig;
	[self configurationRefreshed];
	
	NSString* persistPath = info.persistPath;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[dicConfig writeToFile:persistPath atomically:YES];
	});
}

+ (void)configurationRefreshed
{
	
}

@end
