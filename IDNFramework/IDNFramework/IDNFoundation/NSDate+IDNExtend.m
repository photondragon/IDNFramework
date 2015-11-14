//
//  NSDate+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/12.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSDate+IDNExtend.h"

#ifdef DDLogVerbose
#define NSDateIDNLog DDLogVerbose
#else
#define NSDateIDNLog NSLog
#endif

@implementation NSDate(IDNExtend)

+ (NSString*)dateFormatGMT
{
	static NSString* gmtstr = nil;
	if(gmtstr==nil)
		gmtstr = @"EEE, dd MMM yyyy HH:mm:ss Z";
	return gmtstr;
}

- (NSString*)stringWithFormat:(NSString*)format
{
	static NSDateFormatter* formatter = nil;
	if(formatter==nil)
	{
		formatter = [[NSDateFormatter alloc] init];
		[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"]];
		[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
	}
	formatter.dateFormat = format;
	return [formatter stringFromDate:self];
}

+ (NSDate*)dateFromString:(NSString*)dateString format:(NSString*)format
{
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT+0000"]];
	[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	formatter.dateFormat = format;
	return [formatter dateFromString:dateString];
}

+ (void)measureCode:(void(^)())codeBlock logTitle:(NSString*)title
{
	if(codeBlock==nil)
		return;
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	codeBlock();
	NSTimeInterval elapsedTime = [NSDate timeIntervalSinceReferenceDate] - startTime;
	if(title)
		NSDateIDNLog(@"%@elapsed time = %.3f", title, elapsedTime);
	else
		NSDateIDNLog(@"elapsed time = %.3f", elapsedTime);
}

@end
