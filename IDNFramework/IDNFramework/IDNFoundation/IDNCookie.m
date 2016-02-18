//
//  IDNCookie.m
//  IDNFramework
//
//  Created by photondragon on 16/2/11.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "IDNCookie.h"

@implementation IDNCookie

+ (instancetype)sharedInstance
{
	static id sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{sharedInstance = [self new];});
	return sharedInstance;
}

- (NSString*)savePath
{
	return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"IDNCookies.dat"];
}

- (void)save
{
	NSHTTPCookieStorage *myCookie = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSMutableArray* array = [NSMutableArray new];
	for (NSHTTPCookie *cookie in [myCookie cookies]) {
		[array addObject:cookie.properties];
	}
	if(array.count)
	{
		[array writeToFile:[self savePath] atomically:YES];
	}
}

- (void)load
{
	NSArray* array = [NSArray arrayWithContentsOfFile:[self savePath]];
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (NSDictionary* dicCookie in array) {
		NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:dicCookie];
		[cookieStorage setCookie:cookie];
	}
}

- (NSArray*)cookiesForUrl:(NSString*)url
{
	return [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:url]];
}

- (void)sample
{
	// 寻找URL为HOST的相关cookie，不用担心，步骤2已经自动为cookie设置好了相关的URL信息
	NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"HOST"]]; // 这里的HOST是你web服务器的域名地址
	// 比如你之前登录的网站地址是abc.com（当然前面要加http://，如果你服务器需要端口号也可以加上端口号），那么这里的HOST就是http://abc.com

	// 设置header，通过遍历cookies来一个一个的设置header
	for (NSHTTPCookie *cookie in cookies){

		// cookiesWithResponseHeaderFields方法，需要为URL设置一个cookie为NSDictionary类型的header，注意NSDictionary里面的forKey需要是@"Set-Cookie"
		NSArray *headeringCookie = [NSHTTPCookie cookiesWithResponseHeaderFields:
									[NSDictionary dictionaryWithObject:
									 [[NSString alloc] initWithFormat:@"%@=%@",[cookie name],[cookie value]]
																forKey:@"Set-Cookie"]
																		  forURL:[NSURL URLWithString:@"HOST"]];

		// 通过setCookies方法，完成设置，这样只要一访问URL为HOST的网页时，会自动附带上设置好的header
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:headeringCookie
														   forURL:[NSURL URLWithString:@"HOST"]
												  mainDocumentURL:nil];
	}
}

@end
