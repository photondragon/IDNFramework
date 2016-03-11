//
//  IDNJumpManage.m
//  IDNFramework
//
//  Created by photondragon on 16/3/8.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "IDNJumpManage.h"

@interface IDNJumpHandlerInfo : NSObject
@property(nonatomic,strong) id jumpKey;
@property(nonatomic,strong) id target;
@property(nonatomic) SEL selector;
@end
@implementation IDNJumpHandlerInfo
@end

#pragma mark - 

@implementation IDNJumpManage
{
	NSMutableDictionary* dicHandlerInfos;
}

+ (instancetype)sharedInstance
{
	static id sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{sharedInstance = [self new];});
	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		dicHandlerInfos = [NSMutableDictionary new];
	}
	return self;
}

- (void)addHandler:(nonnull id)handler action:(nonnull SEL)action jumpKey:(nonnull id)jumpKey
{
	if(jumpKey==nil || handler==nil || action==NULL)
		return;
	NSMutableArray* handlerInfos = dicHandlerInfos[jumpKey];
	if(handlerInfos==nil)
	{
		handlerInfos = [NSMutableArray new];
		dicHandlerInfos[jumpKey] = handlerInfos;
	}

	IDNJumpHandlerInfo* handlerInfo = [IDNJumpHandlerInfo new];
	handlerInfo.target = handler;
	handlerInfo.selector = action;
	handlerInfo.jumpKey = jumpKey;

	for (IDNJumpHandlerInfo* info in handlerInfos) {
		if(info.target==handler && info.selector==action) //已经添加过了
			return;
	}
	[handlerInfos addObject:handlerInfo];
}

- (void)delHandler:(nonnull id)handler action:(nullable SEL)action jumpKey:(nonnull id)jumpKey
{
	if(jumpKey==nil || handler==nil)
		return;
	NSMutableArray* handlerInfos = dicHandlerInfos[jumpKey];
	if(handlerInfos.count==0)
		return;
	if(action==NULL) //模糊删除，可删多个
	{
		for (NSInteger i = handlerInfos.count-1; i>=0; i--) {
			IDNJumpHandlerInfo* info = handlerInfos[i];
			if(info.target==handler)
				[handlerInfos removeObjectAtIndex:i];
		}
	}
	else // 精确删除，最多只删一个
	{
		for (NSInteger i = handlerInfos.count-1; i>=0; i--) {
			IDNJumpHandlerInfo* info = handlerInfos[i];
			if(info.target==handler && info.selector==action)
			{
				[handlerInfos removeObjectAtIndex:i];
				return;
			}
		}
	}
}

- (void)jumpWithKey:(id)jumpKey params:(NSDictionary *)params
{
	if(jumpKey==nil)
		return;
	NSArray* handlerInfos = dicHandlerInfos[jumpKey];
	if(handlerInfos.count==0)
		return;

	handlerInfos = [handlerInfos copy];
	for (IDNJumpHandlerInfo* handler in handlerInfos) {
		id target = handler.target;
		SEL selector = handler.selector;
		IMP imp = [target methodForSelector:selector];
		if(imp==0)
			continue;
		void (*func)(id, SEL, id, id) = (void *)imp;
		func(target, selector, jumpKey, params);
	}
}

- (void)jumpIfDelayed
{
	id jumpKey = nil;
	NSDictionary* params = nil;
	@synchronized(self)
	{
		if(_delayJumpKey==nil)
			return;
		jumpKey = _delayJumpKey;
		params = _delayJumpParams;
		_delayJumpKey = nil;
		_delayJumpParams = nil;
	}
	[self jumpWithKey:jumpKey params:params];
}

- (void)delayJumpWithKey:(id)jumpKey params:(NSDictionary *)params
{
	if(jumpKey==nil)
		return;
	_delayJumpKey = jumpKey;
	_delayJumpParams = params;
}

@end
