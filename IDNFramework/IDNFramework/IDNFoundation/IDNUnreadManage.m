//
//  IDNUnreadManage.m
//  IDNFrameworks
//
//  Created by photondragon on 15/7/25.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNUnreadManage.h"
#import "NSPointerArray+IDNExtend.h"

@interface IDNUnreadInfo : NSObject
@property(nonatomic,strong) NSString* key;
@property(nonatomic,strong,readonly) NSMutableSet* subKeys;
@property(nonatomic,strong,readonly) NSMutableSet* parentKeys;
@property(nonatomic,strong,readonly) NSPointerArray* observers;
@end
@implementation IDNUnreadInfo
- (instancetype)init
{
	self = [super init];
	if (self) {
		_subKeys = [NSMutableSet new];
		_parentKeys = [NSMutableSet new];
		_observers = [NSPointerArray weakObjectsPointerArray];
	}
	return self;
}

- (void)addUnreadObserver:(id<IDNUnreadManageObserver>)observer
{
	if([_observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
		return;
	[_observers addPointer:(__bridge void *)(observer)];
}
- (void)delUnreadObserver:(id<IDNUnreadManageObserver>)observer
{
	[_observers removePointerIdentically:(__bridge void *)(observer)];
}
- (void)notifyObserversWithUnreadManager:(IDNUnreadManage*)unreadManager
{
	BOOL needCompact = NO;
	NSString* key = self.key;
	for (id<IDNUnreadManageObserver> observer in _observers) {
		if(observer==nil)
		{
			needCompact = YES;
			continue;
		}
		
		if([observer respondsToSelector:@selector(unreadManager:unreadCountChangedForKey:)])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[observer unreadManager:unreadManager unreadCountChangedForKey:key];
			});
		}
	}
	if(needCompact)
		[_observers compact];
}
@end

@interface IDNUnreadManage()

@property(nonatomic) BOOL needsSave; //是否需要保存。

@end

@implementation IDNUnreadManage
{
	NSMutableDictionary* dicUnreadCounts;
	NSMutableDictionary* dicUnreadInfos; //可以根据key找到所有subkeys和观察者
}

- (instancetype)initWithFile:(NSString*)filePath
{
	if(filePath.length==0)
		return nil;
	self = [super init];
	if (self) {
		_filePath = filePath;
		dicUnreadCounts = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
		if(dicUnreadCounts==nil)
			dicUnreadCounts = [NSMutableDictionary new];
		dicUnreadInfos = [NSMutableDictionary new];
	}
	return self;
}

- (instancetype)init
{
	return nil;
}

- (void)save //立刻保存。不调用此方法也会自动保存。
{
	if([NSThread currentThread]==[NSThread mainThread])
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self saveOnBackground];
		});
	else
		[self saveOnBackground];
}

- (void)saveOnBackground
{
	NSDictionary* dic = nil;
	@synchronized(self)
	{
		dic = [dicUnreadCounts copy];
		self.needsSave = NO;
	}
	[dic writeToFile:_filePath atomically:YES];
}

- (void)setNeedsSave:(BOOL)needsSave
{
	if(_needsSave==needsSave)
		return;
	_needsSave = needsSave;
	if(_needsSave)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self save];
		});
	}
}

- (void)notifyObserversRecursiveForKey:(NSString*)key
{
	IDNUnreadInfo* info = [self infoWithKey:key];
	[info notifyObserversWithUnreadManager:self];
	
	for (NSString* parentKey in info.parentKeys) {
		[self notifyObserversRecursiveForKey:parentKey];
	}
}

- (void)setUnreadCount:(NSInteger)unreadCount forKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	if(unreadCount<0)
		unreadCount = 0;
	
	@synchronized(self)
	{
		NSInteger oldCount = [dicUnreadCounts[key] integerValue];
		if(oldCount==unreadCount)
			return;
		dicUnreadCounts[key] = @(unreadCount);
		self.needsSave = YES;
		[self notifyObserversRecursiveForKey:key];
	}
}
- (void)addUnreadCount:(NSInteger)addCount forKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	if(addCount==0)
		return;
	
	@synchronized(self)
	{
		NSInteger unreadCount = [dicUnreadCounts[key] integerValue];
		unreadCount += addCount;
		if(unreadCount<0)
			unreadCount = 0;
		dicUnreadCounts[key] = @(unreadCount);
		self.needsSave = YES;
		[self notifyObserversRecursiveForKey:key];
	}
}

- (IDNUnreadInfo*)infoWithKey:(NSString*)key
{
	IDNUnreadInfo* info = dicUnreadInfos[key];
	if(info==nil)
	{
		info = [IDNUnreadInfo new];
		info.key = key;
		dicUnreadInfos[key] = info;
	}
	return info;
}

- (void)addSubKey:(NSString*)subKey forKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	NSAssert1(subKey, @"%s: 参数subKey不可为空", __FUNCTION__);
	
	@synchronized(self)
	{
		IDNUnreadInfo* info = [self infoWithKey:key];
		[info.subKeys addObject:subKey];
		IDNUnreadInfo* subInfo = [self infoWithKey:subKey];
		[subInfo.parentKeys addObject:key];
	}
}
- (NSInteger)unreadCountForKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	
	@synchronized(self)
	{
		return [dicUnreadCounts[key] integerValue];
	}
}

- (NSInteger)allUnreadCountForKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	
	@synchronized(self)
	{
		return [self allUnreadCountRecursiveForKey:key];
	}
}
- (NSInteger)allUnreadCountRecursiveForKey:(NSString*)key
{
	NSInteger count = [dicUnreadCounts[key] integerValue];
	
	IDNUnreadInfo* info = [self infoWithKey:key];
	for (NSString* subKey in info.subKeys) {
		count += [self allUnreadCountRecursiveForKey:subKey];
	}
	return count;
}

- (void)addUnreadObserver:(id<IDNUnreadManageObserver>)observer forKey:(NSString*)key
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	@synchronized(self)
	{
		IDNUnreadInfo* info = [self infoWithKey:key];
		[info addUnreadObserver:observer];
	}
}

- (void)delUnreadObserver:(id<IDNUnreadManageObserver>)observer forKey:(NSString*)key;
{
	NSAssert1(key, @"%s: 参数key不可为空", __FUNCTION__);
	@synchronized(self)
	{
		IDNUnreadInfo* info = [self infoWithKey:key];
		[info delUnreadObserver:observer];
	}
}

@end
