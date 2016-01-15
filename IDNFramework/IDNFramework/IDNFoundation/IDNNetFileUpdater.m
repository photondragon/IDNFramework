//
//  IDNNetFileUpdater.m
//  IDNFramework
//
//  Created by photondragon on 15/8/20.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNNetFileUpdater.h"
#import "NSString+IDNExtend.h"
#import "NSTimer+IDNWeakTarget.h"

@implementation IDNNetFileUpdater
{
	NSString* saveDirectory;
	NSMutableDictionary* urlInfos;
	NSTimer* timer;
}

+ (instancetype)sharedInstance
{
	static IDNNetFileUpdater* sharedInstance = nil;
	if(sharedInstance==nil)
	{
		@synchronized(self)
		{
			if(sharedInstance==nil)
				sharedInstance = [[IDNNetFileUpdater alloc] initWithSaveDirectory:[(NSString*)[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"IDNNetFileUpdater"]];
		}
	}
	return sharedInstance;
}

- (instancetype)initWithSaveDirectory:(NSString*)directory
{
	self = [super init];
	if (self) {
		srand(((unsigned)([NSDate timeIntervalSinceReferenceDate]*100000))%100000);
		saveDirectory = directory;
		urlInfos = [NSMutableDictionary new];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:saveDirectory]==NO)
			[saveDirectory mkdir];
	}
	return self;
}

- (void)dealloc
{
	if(timer)
	{
		[timer invalidate];
		timer = nil;
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)checkAndDownload //在主线程调用，其中检测文件是否存在的代码只是在首次启动时调用，所以不用考虑卡顿的问题。
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	NSMutableArray* urls = [NSMutableArray new];
	@synchronized(self)
	{
		for (NSMutableDictionary* info in urlInfos.allValues)
		{
			BOOL isDownloading = [info[@"isDownloading"] boolValue];
			if(isDownloading) //正在更新，直接跳过
				continue;
			
			NSTimeInterval lastUpdateTime = [info[@"lastUpdateTime"] doubleValue];
			NSTimeInterval updateInterval = [info[@"updateInterval"] doubleValue];
			
			if(lastUpdateTime==0) //没有更新过
			{
				if([info[@"forceUpdateOnLaunch"] boolValue]) //首次强制更新
				{
					info[@"isDownloading"] = @YES;
					[urls addObject:info];
					continue;
				}
				else //非强制更新
				{
					NSString* url = info[@"url"];
					if([[NSFileManager defaultManager] fileExistsAtPath:[saveDirectory stringByAppendingPathComponent:[url md5]]]==NO) //文件不存在
					{
						info[@"isDownloading"] = @YES;
						[urls addObject:info];
						continue;
					}
					else // 如果文件存在
					{
						NSTimeInterval delta = updateInterval*( ((NSTimeInterval)rand()) / ((NSTimeInterval)RAND_MAX) );
						lastUpdateTime = now - delta;
						info[@"lastUpdateTime"] = @(lastUpdateTime);
						//continue;
					}
				}
			}
			
			if(updateInterval > 0 && now-lastUpdateTime > updateInterval)
			{
				info[@"isDownloading"] = @YES;
				[urls addObject:info];
			}
		}
		for (NSDictionary* info in urls) {
			[self downloadUrlOnBackground:info[@"url"] lastModified:info[@"lastModified"]];
		}
	}
}

- (void)registerUrl:(NSString*)url updateInterval:(NSTimeInterval)updateInterval forceUpdateOnLaunch:(BOOL)forceUpdateOnLaunch updatedCallback:(void (^)(NSData* data))updatedCallback
{
	if(url.length==0)
		return;
	@synchronized(self)
	{
		[self unregisterUrl:url];
		
		NSMutableDictionary* info = [NSMutableDictionary new];
		info[@"url"] = url;
		info[@"updateInterval"] = @(updateInterval);
		info[@"forceUpdateOnLaunch"] = @(forceUpdateOnLaunch);
		if(updatedCallback)
			info[@"updatedCallback"] = updatedCallback;
		
		urlInfos[url] = info;
		
		if(timer==nil)
		{
			timer = [NSTimer scheduledTimerWithTimeInterval:10.0 weakTarget:self selector:@selector(checkAndDownload) userInfo:nil repeats:YES];
			timer.tolerance = 1;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self checkAndDownload];
			});
		}
	}
}

- (void)unregisterUrl:(NSString*)url
{
	if(url.length==0)
		return;
	@synchronized(self)
	{
	NSMutableDictionary* info = urlInfos[url];
	if(info==nil)
		return;
	// @todo
	[urlInfos removeObjectForKey:url];
	
	if(urlInfos.count==0 && timer)
	{
		[timer invalidate];
		timer = nil;
	}
	}
}

- (NSData*)dataOfUrl:(NSString*)url
{
	if(url.length==0)
		return nil;
	return [NSData dataWithContentsOfFile:[saveDirectory stringByAppendingPathComponent:[url md5]]];
}

- (void)downloadUrlOnBackground:(NSString*)url lastModified:(NSString*)lastModified
{
	if([NSThread currentThread] == [NSThread mainThread])
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			__typeof(self) sself = wself;
			[sself downloadUrl:url lastModified:lastModified];
		});
	}
	else
		[self downloadUrl:url lastModified:lastModified];
}

- (void)downloadUrl:(NSString*)url lastModified:(NSString*)lastModified
{
	NSError* error = nil;
	NSData* data = [IDNNetFileUpdater getFromURL:url parameters:nil error:&error lastModified:&lastModified];
	if(data)
	{
		[data writeToFile:[saveDirectory stringByAppendingPathComponent:[url md5]] atomically:YES];
		NSLog(@"IDNNetFileUpdater: 自动更新文件成功 %@", url);
		[self downloadSuccessWithUrl:url data:data lastModified:lastModified];
	}
	else
	{
		if( error.code==304 && [error.domain isEqualToString:@"IDNNetFileUpdaterNotModified"] )
		{
			NSLog(@"IDNNetFileUpdater: 自动更新文件成功，文件未修改 %@", url);
			[self downloadNotModifiedWithUrl:url];
		}
		else
		{
			NSLog(@"IDNNetFileUpdater: 自动更新文件失败 %@", url);
			NSLog(@"%@", error);
			[self downloadFailedWithUrl:url];
		}
	}
}

- (void)downloadSuccessWithUrl:(NSString*)url data:(NSData*)data lastModified:(NSString*)lastModified
{
	void (^updatedCallback)(NSData* data);
	@synchronized(self)
	{
		NSMutableDictionary* info = urlInfos[url];
		if(info==nil)
			return;
		info[@"isDownloading"] = @NO;
		info[@"lastUpdateTime"] = @([NSDate timeIntervalSinceReferenceDate]);
		if(lastModified)
			info[@"lastModified"] = lastModified;

		updatedCallback = info[@"updatedCallback"];
	}
	if(updatedCallback)
	{
		if(data)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				updatedCallback(data);
			});
		}
	}
}
- (void)downloadNotModifiedWithUrl:(NSString*)url
{
	void (^updatedCallback)(NSData* data);
	@synchronized(self)
	{
		NSMutableDictionary* info = urlInfos[url];
		if(info==nil)
			return;
		info[@"isDownloading"] = @NO;
		info[@"lastUpdateTime"] = @([NSDate timeIntervalSinceReferenceDate]);

		updatedCallback = info[@"updatedCallback"];
	}
	if(updatedCallback)
	{
		NSData* data = [self dataOfUrl:url];
		if(data)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				updatedCallback(data);
			});
		}
	}
}

- (void)downloadFailedWithUrl:(NSString*)url
{
	@synchronized(self)
	{
		NSMutableDictionary* info = urlInfos[url];
		if(info==nil)
			return;
		info[@"isDownloading"] = @NO;
	}
}

#pragma mark 网络请求方法
+ (NSData*)getFromURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error lastModified:(NSString**)lastModified
{
	NSURL* urlWithParam;
//	DDLogDebug(@"GET: %@", url);
//	if(parameters.count==0)
//	{
		urlWithParam = [NSURL URLWithString:url];
//	}
//	else
//	{
//		NSString* parametersString = [self jsonStringFromDictionary:parameters error:error];
//		if(parametersString==nil)
//			return nil;
//		DDLogDebug(@"   %@", parametersString);
//		NSString* string = [parametersString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//		urlWithParam = [NSURL URLWithString:[NSString stringWithFormat:@"%@?p=%@", url,string]];
//	}
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:urlWithParam];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	request.timeoutInterval = 12.0;
	request.HTTPMethod = @"GET";
	if(lastModified && [*lastModified length])
	{
		[request setValue:*lastModified forHTTPHeaderField:@"If-Modified-Since"];
	}
	NSError* netError = nil;
	NSHTTPURLResponse* response;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&netError];
	if(responseData==nil)
	{
//		NSLog(@"%@",netError);
		if (error)
			*error = [self errorFromNetworkError:netError];
		return nil;
	}
	if(response.statusCode==304)
	{
		if(error)
			*error = [NSError errorWithDomain:@"IDNNetFileUpdaterNotModified" code:304 userInfo:nil];
		return nil;
	}
	else{
		if(error)
			*error = nil;
		if(lastModified)
			*lastModified = response.allHeaderFields[@"Last-Modified"];
	}
	return responseData;
}

+ (NSError*)errorFromNetworkError:(NSError*)networkError
{
	if([networkError.domain isEqualToString:NSURLErrorDomain])
	{
		if(networkError.code==NSURLErrorTimedOut)
			return [self errorWithDomain:@"IDNNetFileUpdater" description:@"网络超时"];
		else if(networkError.code==NSURLErrorNotConnectedToInternet)
			return [self errorWithDomain:@"IDNNetFileUpdater" description:@"网络断开"];
	}
	return [self errorWithDomain:@"IDNNetFileUpdater" description:networkError.localizedDescription];
//	return [NSError errorWithDescription:networkError.localizedDescription underlyingError:networkError];
}
+ (NSError*)errorWithDomain:(NSString *)domain description:(NSString*)description
{
	NSDictionary* errorInfo;
	if(description.length)
		errorInfo = @{NSLocalizedDescriptionKey:description};
	else
		errorInfo = nil;
	return [NSError errorWithDomain:domain code:0 userInfo:errorInfo];
}

@end
