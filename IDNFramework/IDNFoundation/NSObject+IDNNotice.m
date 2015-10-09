//
//  NSObject+IDNNotice.m
//
//  Created by photondragon on 15/10/9.
//

#import "NSObject+IDNNotice.h"
#import <objc/runtime.h>
#import "NSObject+IDNPerformSelectorNoWarning.h"

@interface NSObjectIDNNotice : NSObject
@property (nonatomic,copy) NSString* noticeName;
@property(nonatomic,strong) NSMutableArray* subscribers;
@end

@interface NSObjectIDNNoticeSubscriber : NSObject
@property(nonatomic,weak) id target;
@property(nonatomic) SEL selector;
@end
@implementation NSObjectIDNNoticeSubscriber
- (BOOL)noticeWithCustomInfo:(id)customInfo
{
	id strongTarget = _target;
	if(strongTarget==nil)
		return NO;
	[strongTarget performSelectorNoWarning:_selector withObject:customInfo];
	return YES;
}
@end

@implementation NSObjectIDNNotice

- (instancetype)init
{
	self = [super init];
	if (self) {
		_subscribers = [NSMutableArray new];
	}
	return self;
}

- (void)addSubscriberTarget:(id)target selector:(SEL)selector
{
	if(target==nil || selector == 0)
		return;
	for (NSObjectIDNNoticeSubscriber* subscriber in _subscribers) {
		if(target==subscriber.target && selector==subscriber.selector)
			return;
	}
	NSObjectIDNNoticeSubscriber* subscriber = [NSObjectIDNNoticeSubscriber new];
	subscriber.target = target;
	subscriber.selector = selector;
	[_subscribers addObject:subscriber];
}

- (void)delSubscriberTarget:(id)target selector:(SEL)selector
{
	if(target==nil)
		return;
	for (NSInteger i = _subscribers.count-1; i>=0; i--) {
		NSObjectIDNNoticeSubscriber* subscriber = _subscribers[i];
		if(target!=subscriber.target || (selector && selector!=subscriber.selector))
			continue;
		[_subscribers removeObjectAtIndex:i];
	}
}

- (void)noticeWithCustomInfo:(id)customInfo
{
	NSInteger count = _subscribers.count;
	for (NSInteger i = 0; i<count; i++) {
		NSObjectIDNNoticeSubscriber* subscriber = _subscribers[i];
		if([subscriber noticeWithCustomInfo:customInfo]==NO) //subscriber.target已被释放
		{
			[_subscribers removeObjectAtIndex:i];
			i--;
		}
	}
}

@end

@implementation NSObject(IDNNotice)

static char bindDictionaryKey = 0;

- (NSMutableDictionary*)bindedDictOfNSObjectIDNNotice
{
	return objc_getAssociatedObject(self, &bindDictionaryKey);
}
- (NSMutableDictionary*)autoBindedDictOfNSObjectIDNNotice
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDictionaryKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDictionaryKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

#pragma mark 发出通知

- (void)notice:(NSString*)noticeName customInfo:(id)customInfo;
{
	if(noticeName==nil)
		return;
	
	NSMutableDictionary* dicNotices = [self bindedDictOfNSObjectIDNNotice];
	NSObjectIDNNotice* notice = dicNotices[noticeName];
	if(notice==nil)
		return;
	[notice noticeWithCustomInfo:customInfo];
}

#pragma mark 订阅/取消订阅Notice

- (void)subscribeNotice:(NSString*)noticeName subscriber:(id)subscriber selector:(SEL)selector;
{
	if(noticeName==nil || subscriber==nil || selector==0)
		return;
	
	NSMutableDictionary* dicNotices = [self autoBindedDictOfNSObjectIDNNotice];
	NSObjectIDNNotice* notice = dicNotices[noticeName];
	if(notice==nil)
	{
		notice = [NSObjectIDNNotice new];
		notice.noticeName = noticeName;
		dicNotices[noticeName] = notice;
	}
	[notice addSubscriberTarget:subscriber selector:selector];
}

- (void)unsubscribeNotice:(NSString*)noticeName
{
	[self unsubscribeNotice:noticeName subscriber:nil selector:0];
}
- (void)unsubscribeNotice:(NSString*)noticeName subscriber:(id)subscriber
{
	[self unsubscribeNotice:noticeName subscriber:subscriber selector:0];
}
- (void)unsubscribeNotice:(NSString*)noticeName subscriber:(id)subscriber selector:(SEL)selector
{
	if(noticeName==nil)
		return;
	NSMutableDictionary* dicNotices = [self bindedDictOfNSObjectIDNNotice];
	if(dicNotices==nil)
		return;
	
	if(subscriber==nil)
	{
		[dicNotices removeObjectForKey:noticeName];
		return;
	}
	
	NSObjectIDNNotice* notice = dicNotices[noticeName];
	if(notice==nil)
		return;
	[notice delSubscriberTarget:subscriber selector:selector];
}

@end
