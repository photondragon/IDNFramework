//
//  NSTimer+IDNWeakTarget.m
//  IDNFramework
//
//  Created by photondragon on 15/8/21.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSTimer+IDNWeakTarget.h"

@interface NSTimerIDNWeakTargetSelector : NSObject
@property (nonatomic,weak) id weakTarget;
@property(nonatomic) SEL selector;
@property(nonatomic,weak) NSTimer* timer;
@end
@implementation NSTimerIDNWeakTargetSelector

- (void)performTargetSelector:(id)userInfo
{
	if(_weakTarget==nil)
	{
		[_timer invalidate];
		return;
	}
	[_weakTarget performSelector:_selector withObject:userInfo afterDelay:0];
}
@end

@implementation NSTimer(IDNWeakTarget)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
	NSTimerIDNWeakTargetSelector* t = [NSTimerIDNWeakTargetSelector new];
	t.weakTarget = weakTarget;
	t.selector = selector;
	NSTimer* timer = [self timerWithTimeInterval:ti target:t selector:@selector(performTargetSelector:) userInfo:userInfo repeats:repeats];
	t.timer = timer;
	return timer;
}
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
	NSTimerIDNWeakTargetSelector* t = [NSTimerIDNWeakTargetSelector new];
	t.weakTarget = weakTarget;
	t.selector = selector;
	NSTimer* timer = [self scheduledTimerWithTimeInterval:ti target:t selector:@selector(performTargetSelector:) userInfo:userInfo repeats:repeats];
	t.timer = timer;
	return timer;
}

- (instancetype)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
	NSTimerIDNWeakTargetSelector* t = [NSTimerIDNWeakTargetSelector new];
	t.weakTarget = weakTarget;
	t.selector = selector;
	NSTimer* timer = [self initWithFireDate:(NSDate *)date interval:ti target:t selector:@selector(performTargetSelector:) userInfo:userInfo repeats:repeats];
	t.timer = timer;
	return timer;
}

@end
