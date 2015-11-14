//
//  IDNFileCache.m
//  IDNFramework
//
//  Created by photondragon on 15/6/22.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNFileCache.h"
#import <CommonCrypto/CommonCrypto.h>
#import <UIKit/UIKit.h>

@implementation IDNFileCache

+ (instancetype)sharedCache
{
	static IDNFileCache* sharedCache = nil;
	if(sharedCache==nil)
	{
		@synchronized(self)
		{
			if(sharedCache==nil)
			{
				NSArray *cacPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
				NSString *cachePath = [cacPath objectAtIndex:0];
				sharedCache = [[IDNFileCache alloc] initWithLoalCacheDir:[NSString stringWithFormat:@"%@/defaultIDNFileCacheDir",cachePath]];
			}
		}
	}
	return sharedCache;
}

- (instancetype)init
{
	NSAssert1(0, @"不能直接调用初始化函数%s", __FUNCTION__);
	return nil;
}

- (instancetype)initWithLoalCacheDir:(NSString *)cacheDir
{
	NSAssert1(cacheDir.length, @"%s: 缓存目录不可为空", __FUNCTION__);
	self = [super init];
	if (self) {
		unichar lastchar = [cacheDir characterAtIndex:cacheDir.length-1];
		if (lastchar == '/') //最后一个字符是目录分隔符/
			cacheDir = [cacheDir substringWithRange:NSMakeRange(0, cacheDir.length-1)];

		BOOL isDir = NO;
		if([[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&isDir])
		{
			if(isDir==NO) //
			{
				NSLog(@"指定的缓存目录是个文件: %@", cacheDir);
				return nil;
			}
			if([[NSFileManager defaultManager] isWritableFileAtPath:cacheDir]==NO ||
			   [[NSFileManager defaultManager] isExecutableFileAtPath:cacheDir]==NO)
			{
				NSLog(@"缓存目录没有写权限: %@", cacheDir);
				return nil;
			}
		}
		else //指定缓存目录不存在
		{
			if(NO==[[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil])
			{
				NSLog(@"无法创建缓存目录: %@", cacheDir);
				return nil;
			}
		}
		_localCacheDir = cacheDir;
	}
	return self;
}

- (NSString*)md5OfString:(NSString*)str
{
	NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(data.bytes, (CC_LONG)data.length, buffer);
	return [NSString
	  stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
	  buffer[0], buffer[1], buffer[2], buffer[3],
	  buffer[4], buffer[5], buffer[6], buffer[7],
	  buffer[8], buffer[9], buffer[10], buffer[11],
	  buffer[12], buffer[13], buffer[14], buffer[15]
	  ];
}

#pragma mark 从缓存获取

- (NSData*)dataWithKey:(NSString*)key{
	return [self dataWithKey:key cacheAge:0];
}

- (NSData*)dataWithKey:(NSString*)key cacheAge:(NSTimeInterval)cacheAge
{
	if(key==nil)
		key = @"";
	if(cacheAge<0)
		cacheAge = 0;

	NSString* md5 = [self md5OfString:key];
	NSString* filePath = [NSString stringWithFormat:@"%@/%@", _localCacheDir, md5];

	@synchronized(self)
	{
		if(cacheAge>0)//要检测文件是否过期
		{
			NSDictionary* fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
			if(fileAttr==nil)
				return nil;
			NSTimeInterval mTime = [(NSDate*)fileAttr[NSFileModificationDate] timeIntervalSinceReferenceDate];
			if([NSDate timeIntervalSinceReferenceDate]-mTime>cacheAge)//过期
				return nil;
		}
		return [NSData dataWithContentsOfFile:filePath];
	}
}

- (BOOL)isFileExistWithKey:(NSString*)key
{
	return [self isFileExistWithKey:key cacheAge:0];
}

- (BOOL)isFileExistWithKey:(NSString*)key cacheAge:(NSTimeInterval)cacheAge
{
	if(key==nil)
		key = @"";
	if(cacheAge<0)
		cacheAge = 0;

	NSString* md5 = [self md5OfString:key];
	NSString* filePath = [NSString stringWithFormat:@"%@/%@", _localCacheDir, md5];
	@synchronized(self)
	{
		if(cacheAge>0)//要检测文件是否过期
		{
			NSDictionary* fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
			if(fileAttr==nil)
				return NO;
			NSTimeInterval mTime = [(NSDate*)fileAttr[NSFileModificationDate] timeIntervalSinceReferenceDate];
			if([NSDate timeIntervalSinceReferenceDate]-mTime>cacheAge)//过期
				return NO;
			return YES;
		}
		return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	}
}

#pragma mark 向缓存添加

- (void)cacheFileWithData:(NSData*)data forKey:(NSString*)key
{
	if(data==nil)
		return;
	if(key==nil)
		key = @"";

	NSString* md5 = [self md5OfString:key];
	NSString* filePath = [NSString stringWithFormat:@"%@/%@", _localCacheDir, md5];
	@synchronized(self)
	{
		[data writeToFile:filePath atomically:YES];
	}
}

- (void)cacheFileWithPath:(NSString*)filePath forKey:(NSString*)key
{
	if(filePath.length==0)
		return;
	if(key==nil)
		key = @"";

	NSFileManager* defaultManager = [NSFileManager defaultManager];

	BOOL isDir;
	if([defaultManager fileExistsAtPath:filePath isDirectory:&isDir]==NO)//来源文件filePath不存在
		return;
	if(isDir)//来源文件filePath是个目录
		return;
	if([defaultManager isDeletableFileAtPath:filePath]==NO) //来源文件不可删除
		return;

	NSString* md5 = [self md5OfString:key];
	NSString* cachePath = [NSString stringWithFormat:@"%@/%@", _localCacheDir, md5];

	@synchronized(self)
	{
		if([defaultManager fileExistsAtPath:cachePath])//缓存文件已存在
			[defaultManager removeItemAtPath:cachePath error:nil];
		[defaultManager moveItemAtPath:filePath toPath:cachePath error:nil];
		[defaultManager setAttributes:@{NSFileModificationDate:[NSDate date]} ofItemAtPath:cachePath error:nil];//更新mtime
	}
}

#pragma mark 删除/清空

- (void)clear
{
	[self removeFilesWithCacheAge:0];
}
- (void)removeFileForKey:(NSString*)key
{
	if(key==nil)
		key = @"";
	NSString* md5 = [self md5OfString:key];
	NSString* cachePath = [NSString stringWithFormat:@"%@/%@", _localCacheDir, md5];
	@synchronized(self)
	{
		[[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
	}
}

- (void)removeFilesOnBackgroundWithCacheAge:(NSTimeInterval)cacheAge
{
	__block UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;

	taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[[UIApplication sharedApplication] endBackgroundTask:taskID];
	}];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self removeFilesWithCacheAge:cacheAge];
		[[UIApplication sharedApplication] endBackgroundTask:taskID];
	});
}

- (void)removeFilesWithCacheAge:(NSTimeInterval)cacheAge
{
	if(cacheAge<0)
		return;

	NSFileManager* defaultManager = [NSFileManager defaultManager];

	@synchronized(self)
	{
		NSArray* files = [defaultManager contentsOfDirectoryAtPath:_localCacheDir error:nil];
		for (NSString*file in files)
		{
			NSString* path = [NSString stringWithFormat:@"%@/%@", _localCacheDir, file];
			if(cacheAge>0)
			{
				NSDictionary* fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
				if(fileAttr==nil)
					continue;
				NSTimeInterval mTime = [(NSDate*)(fileAttr[NSFileModificationDate]) timeIntervalSinceReferenceDate];
				if([NSDate timeIntervalSinceReferenceDate]-mTime<cacheAge)//没过期
					continue; //跳过
			}
			[defaultManager removeItemAtPath:path error:nil];
		}
	}
}

@end
