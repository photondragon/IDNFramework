//
//  IDNNetwork.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNNetwork.h"
#import "NSDictionary+IDNExtend.h"

#ifdef DEBUG
#define IDNNetworkLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define IDNNetworkLog(format, ...)
#endif

#define IDNNetworErrorDomain @"IDNErrorDomainNetwork" //IDNNetworError网络异常

static NSTimeInterval dateCorrection = 0; //时间校正值。localTime+dateCorrection=serverTime

@implementation IDNNetwork

+ (void)correctDateWithServerDate:(NSString*)gmtDateString
{
	if(gmtDateString.length==0)
		return;
	static NSDateFormatter* gmtFormatter = nil;
	if(gmtFormatter==nil)
	{
		gmtFormatter = [[NSDateFormatter alloc] init];
		[gmtFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		[gmtFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
	}
	NSDate* serverDate = [gmtFormatter dateFromString:gmtDateString];
	if(serverDate==nil)
		return;
	NSTimeInterval delta = serverDate.timeIntervalSinceReferenceDate - [NSDate timeIntervalSinceReferenceDate];
	IDNNetworkLog(@"********时间差%.0f********", delta);
	if(delta<=60.0 && delta>=-60.0)//相差两分钟以内不作校正
		delta = 0;
	dateCorrection = delta;
}
+ (NSDate*)dateOfServer
{
	return [NSDate dateWithTimeIntervalSinceNow:dateCorrection];
}
+ (NSTimeInterval)timeIntervalOfServerSinceReferenceDate
{
	return [NSDate timeIntervalSinceReferenceDate]+dateCorrection;
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
+ (NSError*)errorFromNetworkError:(NSError*)networkError
{
	if([networkError.domain isEqualToString:NSURLErrorDomain])
	{
		if(networkError.code==NSURLErrorTimedOut)
			return [self errorWithDomain:IDNNetworErrorDomain description:@"网络超时"];
		else if(networkError.code==NSURLErrorNotConnectedToInternet)
			return [self errorWithDomain:IDNNetworErrorDomain description:@"网络断开"];
	}
	return [self errorWithDomain:IDNNetworErrorDomain description:networkError.localizedDescription];
//	return [NSError errorWithDescription:networkError.localizedDescription underlyingError:networkError];
}

+ (NSDictionary*)getDictionaryFromURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error
{
	NSData* dataResponse = [self getFromURL:url parameters:parameters error:error];
	if(dataResponse==nil)
		return nil;
	return [self dictionaryFromJSONData:dataResponse error:error];
}

+ (NSData*)getFromURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error
{
	NSURL* urlWithParam;
	IDNNetworkLog(@"GET: %@", url);
	if(parameters.count==0)
	{
		urlWithParam = [NSURL URLWithString:url];
	}
	else
	{
		NSString* parametersString = [self jsonStringFromDictionary:parameters error:error];
		if(parametersString==nil)
			return nil;
		IDNNetworkLog(@"   %@", parametersString);
		NSString* string = [parametersString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		urlWithParam = [NSURL URLWithString:[NSString stringWithFormat:@"%@?p=%@", url,string]];
	}

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:urlWithParam];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	request.timeoutInterval = 12.0;
	request.HTTPMethod = @"GET";
	NSError* netError = nil;
	NSHTTPURLResponse* response;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&netError];
	if(responseData==nil)
	{
		IDNNetworkLog(@"%@",netError);
		if (error)
			*error = [IDNNetwork errorFromNetworkError:netError];
		return nil;
	}
	[self correctDateWithServerDate:[response allHeaderFields][@"Date"]];
	if(error)
		*error = nil;
	return responseData;
}

+ (NSDictionary*)postToURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error
{
	NSData* postData = [self jsonDataFromDictionary:parameters error:error];
	if(postData==nil)
		return nil;

	NSData* dataResponse = [self postToURL:url bodyData:postData error:error];
	if(dataResponse==nil)
		return nil;

	return [self dictionaryFromJSONData:dataResponse error:error];
}

+ (NSData*)postToURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error
{
	IDNNetworkLog(@"POST: %@", url);
	IDNNetworkLog(@"    %@", [[NSString alloc] initWithData:bodyData encoding:NSASCIIStringEncoding]);

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	request.timeoutInterval = 12.0;
	request.HTTPMethod = @"POST";
	[request setValue:[@([bodyData length]) description] forHTTPHeaderField:@"Content-Length"];
	//	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:bodyData];

	//	IDNNetworkLog(@"%@", [request allHTTPHeaderFields]);

	NSError* netError = nil;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&netError];
	if(responseData==nil)
	{
		IDNNetworkLog(@"%@",netError);
		if (error)
			*error = [IDNNetwork errorFromNetworkError:netError];
		return nil;
	}

	//////显示Cookie/////
	//	NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	//	for (NSHTTPCookie *cookie in [cookieJar cookies]) {
	//		IDNNetworkLog(@"%@", cookie);
	//	}

	return responseData;
}

+ (NSDictionary*)putToURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error
{
	// 将参数转为JSON格式
	NSData* postData = [self jsonDataFromDictionary:parameters error:error];
	if(postData==nil)
		return nil;

	NSData* dataResponse = [self putToURL:url bodyData:postData error:error];
	if(dataResponse==nil)
		return nil;
	return [self dictionaryFromJSONData:dataResponse error:error];
}

+ (NSData*)putToURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error
{
	IDNNetworkLog(@"PUT: %@", url);
	IDNNetworkLog(@"    %@", [[NSString alloc] initWithData:bodyData encoding:NSASCIIStringEncoding]);

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	request.timeoutInterval = 12.0;
	request.HTTPMethod = @"PUT";
	[request setValue:[@([bodyData length]) description] forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:bodyData];

	NSError* netError = nil;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&netError];
	if(responseData==nil)
	{
		IDNNetworkLog(@"%@",netError);
		if (error)
			*error = [IDNNetwork errorFromNetworkError:netError];
		return nil;
	}
	return responseData;
}

+ (NSDictionary*)deleteAtURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error
{
	// 将参数转为JSON格式
	NSData* postData = [self jsonDataFromDictionary:parameters error:error];
	//	if(postData==nil)
	//		return nil;

	NSData* dataResponse = [self deleteAtURL:url bodyData:postData error:error];
	if(dataResponse==nil)
		return nil;
	return [self dictionaryFromJSONData:dataResponse error:error];
}

+ (NSData*)deleteAtURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error
{
	IDNNetworkLog(@"DELETE: %@", url);
	if(bodyData.length)
		IDNNetworkLog(@"    %@", [[NSString alloc] initWithData:bodyData encoding:NSASCIIStringEncoding]);

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	request.timeoutInterval = 12.0;
	request.HTTPMethod = @"DELETE";
	[request setValue:[@([bodyData length]) description] forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:bodyData];

	NSError* netError = nil;
	NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&netError];
	if(responseData==nil)
	{
		IDNNetworkLog(@"%@",netError);
		if (error)
			*error = [IDNNetwork errorFromNetworkError:netError];
		return nil;
	}
	return responseData;
}

#pragma mark JSON

+ (NSDictionary*)dictionaryFromJSONData:(NSData*)jsonData error:(NSError**)error
{
	NSDictionary *dicResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:error];
	if(dicResponse==nil)
	{
		IDNNetworkLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
		if(error)
			*error = [self errorWithDomain:IDNNetworErrorDomain description:@"服务器返回无效数据"];
		return nil;
	}
	IDNNetworkLog(@"%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
	if(error)
		*error = nil;
	return [dicResponse dictionaryWithoutNSNull];
}

+ (NSData*)jsonDataFromDictionary:(NSDictionary*)dic error:(NSError**)error
{
	if(dic==nil)
		return nil;
	NSData* jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:error];

	return jsonData;
}

+ (NSString*)jsonStringFromDictionary:(NSDictionary*)dic error:(NSError**)error
{
	NSData* jsonData = [self jsonDataFromDictionary:dic error:error];
	if(jsonData==nil)
		return nil;
	return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
