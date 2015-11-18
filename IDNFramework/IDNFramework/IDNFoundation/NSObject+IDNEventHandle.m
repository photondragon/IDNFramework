//
//  NSObject+IDNEventHandle.m
//
//  Created by photondragon on 15/9/10.
//

#import "NSObject+IDNEventHandle.h"
#import <objc/runtime.h>
#import "NSObject+IDNDeallocBlock.h"
#import "NSObject+IDNPerformSelector.h"

@interface NSObjectIDNEventHandleWeakTarget : NSObject
@property (nonatomic,weak) id weakTarget;
@property(nonatomic) SEL selector;
@end
@implementation NSObjectIDNEventHandleWeakTarget
@end

@implementation NSObject(IDNEventHandle)

static char bindDictionaryKey = 0;

- (NSMutableDictionary*)bindedDictOfNSObjectIDNEventHandle
{
	return objc_getAssociatedObject(self, &bindDictionaryKey);
}
- (NSMutableDictionary*)autoBindedDictOfNSObjectIDNEventHandle
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDictionaryKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDictionaryKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

#pragma mark 触发事件

- (void)triggerEvent:(NSString*)eventName customInfo:(id)customInfo
{
	if(eventName==nil)
		eventName = (NSString*)[NSNull null];
	
	NSMutableDictionary* dicResponseHandlers = [self bindedDictOfNSObjectIDNEventHandle];
	
	void (^handler)(id customInfo) = dicResponseHandlers[eventName];
	if(handler)
		handler(customInfo);
	else
	{
		void (^defaultHandler)(NSString* eventName, id customInfo) = dicResponseHandlers[eventName];
		if(defaultHandler)
			defaultHandler(eventName, customInfo);
	}
}

#pragma mark 设置/取消事件处理Handler

- (void)handleEvent:(NSString*)eventName target:(id)target selector:(SEL)selector
{
	if(eventName==nil || target==nil || selector==0)
		return;
	
	NSObjectIDNEventHandleWeakTarget* delegator = [NSObjectIDNEventHandleWeakTarget new];
	delegator.weakTarget = target;
	delegator.selector = selector;
	__weak __typeof(self) wself = self;
	[target addDeallocBlock:^{
		__typeof(self) sself = wself;
		[sself stopHandleEvent:eventName];
	}];
	
	NSMutableDictionary* dicResponseHandlers = [self autoBindedDictOfNSObjectIDNEventHandle];

	dicResponseHandlers[eventName] = ^(id customInfo){
		[delegator.weakTarget performSelectorNoWarning:delegator.selector withObject:customInfo];
	};
}

- (void)handleEvent:(NSString*)eventName handler:(void(^)(id customInfo))handler
{
	if(eventName==nil || handler==nil)
		return;
	
	NSMutableDictionary* dicResponseHandlers = [self autoBindedDictOfNSObjectIDNEventHandle];
	
	dicResponseHandlers[eventName] = handler;
}

- (void)stopHandleEvent:(NSString*)eventName
{
	if(eventName==nil)
		return;
	
	NSMutableDictionary* dicResponseHandlers = [self bindedDictOfNSObjectIDNEventHandle];

	[dicResponseHandlers removeObjectForKey:eventName];
}

#pragma mark 默认事件处理Handler

- (void)setEventDefaultTarget:(id)target selector:(SEL)selector
{
	if(target==nil || selector==0)
		return;
	
	NSObjectIDNEventHandleWeakTarget* delegator = [NSObjectIDNEventHandleWeakTarget new];
	delegator.weakTarget = target;
	delegator.selector = selector;
	__weak __typeof(self) wself = self;
	[target addDeallocBlock:^{
		__typeof(self) sself = wself;
		[sself unsetEventDefaultHandler];
	}];
	
	NSMutableDictionary* dicResponseHandlers = [self autoBindedDictOfNSObjectIDNEventHandle];
	
	dicResponseHandlers[[NSNull null]] = ^(NSString* eventName, id customInfo){
		[delegator.weakTarget performSelectorNoWarning:delegator.selector withObject:eventName withObject:customInfo];
	};
}

- (void)setEventDefaultHandler:(void(^)(NSString* eventName, id customInfo))handler
{
	if(handler==nil)
		return;
	
	NSMutableDictionary* dicResponseHandlers = [self autoBindedDictOfNSObjectIDNEventHandle];
	
	dicResponseHandlers[[NSNull null]] = handler;
}

- (void)unsetEventDefaultHandler
{
	NSMutableDictionary* dicResponseHandlers = [self bindedDictOfNSObjectIDNEventHandle];
	
	[dicResponseHandlers removeObjectForKey:[NSNull null]];
}

@end
