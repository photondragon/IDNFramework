//
//  NSNotificationCenter+IDN.m
//  IDNFramework
//
//  Created by photondragon on 16/3/8.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "NSNotificationCenter+IDN.h"
#import "NSObject+IDNCustomObject.h"
#import "NSObject+IDNDeallocBlock.h"
#import "NSObject+IDNPerformSelector.h"

#if 0 // log

#ifdef DDLogInfo
#define InnerLog DDLogInfo
#else
#define InnerLog NSLog
#endif

#else

#define InnerLog(...)

#endif

@interface NSNotificationCenter_IDN_Observer : NSObject
@property(nonatomic,weak) id observer;
@property(nonatomic,weak) id notiSender;
@property(nonatomic,copy) NSString* notiName;
@property(nonatomic) SEL selector;
@end
@implementation NSNotificationCenter_IDN_Observer
- (void)receiveNoti:(NSNotification *)noti
{
	InnerLog(@"RCV inner observer[%p]", self);
	[self.observer performSelectorNoWarning:_selector withObject:noti];
}
@end

#pragma mark -

#define InnerObserversKey @"NSNotificationCenter_IDN_InnerObserversKey"

@implementation NSNotificationCenter(IDN)

- (void)NSNotificationCenter_IDN_addInnerObserver:(NSNotificationCenter_IDN_Observer*)innerObserver
{
	if(innerObserver==nil)
		return;

	NSMutableArray* innerObservers = [self customObjectForKey:InnerObserversKey];
	if(innerObservers==nil)
	{
		innerObservers = [NSMutableArray new];
		[self setCustomObject:innerObservers forKey:InnerObserversKey];
	}

	[innerObservers addObject:innerObserver];
	[self addObserver:innerObserver selector:@selector(receiveNoti:) name:innerObserver.notiName object:innerObserver.notiSender];
	InnerLog(@"ADD inner observer[%p]", innerObserver);

	// observer或notiSender释放时，自动删除观察者
	__weak __typeof(self) wself = self; // 不能使用weak self，否则会
	__weak __typeof(innerObserver) wInnerObserver = innerObserver;
	@autoreleasepool {
		[innerObserver.observer addDeallocatedBlock:^{
			__typeof(self) sself = wself;
			[sself NSNotificationCenter_IDN_removeInnerObserver:wInnerObserver];
		}];
		[innerObserver.notiSender addDeallocBlock:^{
			__typeof(self) sself = wself;
			[sself NSNotificationCenter_IDN_removeInnerObserver:wInnerObserver];
		}];
	}
	/* 上面必须使用@autoreleasepool块，否则会造成observer和notiSender不能被及时释放。
	 * 因为innerObserver.observer相当于[innerObserver observer]，这个方法调用会将返回
	 * 的observer对象autorelease，这应该是ARC的特性（因为重载这个方法也没用，observer对象
	 * 还是会进入自动释放池），如果你本函数返回后在外部将observer对象置为nil，将其引用计数变
	 * 为0，observer对象也不会立刻释放，因为这个对象已经进入了自动释放池。
	 *
	 * innerObserver.notiSender也会有同样的问题。
	 */
}

- (void)NSNotificationCenter_IDN_removeInnerObserver:(NSNotificationCenter_IDN_Observer*)innerObserver
{
	if(innerObserver==nil)
		return;

	NSMutableArray* innerObservers = [self customObjectForKey:InnerObserversKey];
	if(innerObservers==nil)
		return;

	NSInteger oldCount = innerObservers.count;

	[self removeObserver:innerObserver name:innerObserver.notiName object:innerObserver.notiSender];

	[innerObservers removeObjectIdenticalTo:innerObserver];
	if(innerObservers.count!=oldCount)
		InnerLog(@"DEL inner observer[%p]", innerObserver);
}

- (NSNotificationCenter_IDN_Observer*)findInnerObserverWithObserver:(id)observer name:(NSString *)notiName object:(id)notiSender
{
	NSMutableArray* innerObservers = [self customObjectForKey:InnerObserversKey];
	if(innerObservers==nil)
		return nil;

	for (NSNotificationCenter_IDN_Observer* innerObserver in innerObservers) {
		if(observer==innerObserver.observer &&
		   ((notiName==nil && innerObserver.notiName==nil) || [notiName isEqualToString:innerObserver.notiName]) &&
		   ((notiSender==nil && innerObserver.notiSender==nil) || [notiSender isEqual:innerObserver.notiSender])
		   )
			return innerObserver;
	}
	return nil;
}

- (NSArray*)findInnerObserversWithObserver:(id)observer
{
	NSMutableArray* innerObservers = [self customObjectForKey:InnerObserversKey];
	if(innerObservers==nil)
		return nil;

	NSMutableArray* array = [NSMutableArray new];
	for (NSNotificationCenter_IDN_Observer* innerObserver in innerObservers) {
		if(observer==innerObserver.observer)
			[array addObject:innerObserver];
	}
	if(array.count)
		return array;
	return nil;
}

- (void)removeWeakObserver:(id)observer
{
	if(observer==nil)
		return;
	NSArray* removes = [self findInnerObserversWithObserver:observer];
	for (NSNotificationCenter_IDN_Observer* innerObserver in removes) {
		[self NSNotificationCenter_IDN_removeInnerObserver:innerObserver];
	}
}

- (void)removeWeakObserver:(id)observer name:(NSString *)notiName object:(id)notiSender
{
	if(observer==nil)
		return;
	NSNotificationCenter_IDN_Observer* innerObserver = [self findInnerObserverWithObserver:observer name:notiName object:notiSender];
	if(innerObserver)
		[self NSNotificationCenter_IDN_removeInnerObserver:innerObserver];
}

- (void)addWeakObserver:(id)observer selector:(SEL)aSelector name:(NSString *)notiName object:(id)notiSender
{
	if(observer==nil || aSelector==nil || (notiName.length==0 && notiSender==nil))
		return;
	NSNotificationCenter_IDN_Observer* innerObserver = [self findInnerObserverWithObserver:observer name:notiName object:notiSender];
	if(innerObserver) //观察者已存在
		return;

	innerObserver = [[NSNotificationCenter_IDN_Observer alloc] init];
	innerObserver.observer = observer;
	innerObserver.notiName = notiName;
	innerObserver.notiSender = notiSender;
	innerObserver.selector = aSelector;

	[self NSNotificationCenter_IDN_addInnerObserver:innerObserver];
}

@end
