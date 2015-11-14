//
//  IDNItemCenter.m
//  testItemCenter
//
//  Created by photondragon on 15/7/18.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNItemCenter.h"
#import "NSPointerArray+IDNExtend.h"
#import "NSError+IDNExtend.h"

@interface IDNItemCenterRequest : NSObject
@property(nonatomic,strong) id itemID;
@property(nonatomic) BOOL sended; // 请求是否已经发出
@property(nonatomic,strong) id retItem; //返回的对象
@property(nonatomic,strong) NSError* error;
@end
@implementation IDNItemCenterRequest
{
	NSMutableArray* callbacks;
}
- (void)registerFinishCallback:(void (^)(id item, NSError* error))callback
{
	if(callback==nil)
		return;
	@synchronized(self)
	{
		if(callbacks==nil)
			callbacks = [NSMutableArray new];
		[callbacks addObject:callback];
	}
}
- (void)finishCallbacks //调用所有回调
{
	for (void (^callback)(id item, NSError* error) in callbacks) {
		callback(self.retItem, self.error);
	}
}
@end

@interface IDNItemCenter()

@property(nonatomic) BOOL needsSendRequests; //是否需要向服务器发送请求

@end

@implementation IDNItemCenter
{
	NSMutableDictionary* dicRequests; //id=itemID,key=?。对请求队列的修改有三处，创建添加请求、发送请求、完成并移除请求，这三处需要加锁。
	NSPointerArray* observers;
	NSLock* localItemsLock; //本地Items锁
	NSCache* cache;
}

+ (instancetype)defaultCenter
{
	static id defaultCenter = nil;
	if(defaultCenter==nil)
	{
		defaultCenter = [self new];
	}
	return defaultCenter;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		dicRequests = [NSMutableDictionary new];
		observers = [NSPointerArray weakObjectsPointerArray];
		localItemsLock = [NSLock new];
		cache = [[NSCache alloc] init];
		cache.countLimit = 0;
		_combineRequests = YES;
	}
	return self;
}

// 便捷方法。内部调用了itemsFromLocalWithIDs:
- (id)itemFromLocalWithID:(id)itemID
{
	if(itemID==nil)
		return nil;
	NSDictionary* dicItems = [self itemsFromLocalWithIDs:@[itemID]];
#ifdef DEBUG
	if(dicItems && [dicItems isKindOfClass:[NSDictionary class]]==NO)
	{
		NSString* errstr = [NSString stringWithFormat:@"[%@ fetchItemsFromServerWithIDs:callback:]回调返回的参数dicItems不是字典，而是%@", NSStringFromClass(self.class), NSStringFromClass(dicItems.class)];
		NSLog(@"%@", errstr);
		return nil;
	}
#endif
	return dicItems[itemID];
}

//只从内存缓存中获取Item。如果没有或者过期，会异步从服务器提取，并通过Observer返回最新的Item。
//- (id)itemInMemoryWithID:(id)itemID
//{
//	NSAssert(itemID, @"%s: 参数itemID不可为nil", __FUNCTION__);
//	
//	id item;
//	item = [cache objectForKey:itemID];
//	if(item==nil)//内存中没有item
//	{
//		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//			[localItemsLock lock];
//			id item = [self itemFromLocalWithID:itemID];
//			[localItemsLock unlock];
//			
//			if(item)
//				[cache setObject:item forKey:itemID]; //更新内存缓存
//			
//			if(item==nil || [self isItemExpired:item])//本地没有item，或者本地item已经过期
//			{
//				[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
//			}
//			
//			if(item) //本地有item
//			{
//				// 通知观察者Item被更新（这里实际上Item并没有更新，只是作为一种通知机制）
//				__weak __typeof(self) wself = self;
//				dispatch_async(dispatch_get_main_queue(), ^{
//					__typeof(self) sself = wself;
//					[sself notifyObserversWithUpdatedItems:@[item]];
//				});
//			}
//		});
//	}
//	else if([self isItemExpired:item])//内存中的item已经过期
//	{
//		[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
//	}
//	return item;
//}

// 可能会在任意线程被调用
- (void)getItemWithID:(id)itemID callback:(void (^)(id item, NSError* error))callback
{
	NSAssert(itemID, @"%s: 参数itemID不可为nil", __FUNCTION__);
	
	id item;
	item = [cache objectForKey:itemID];
	if(item==nil)//内存中没有item
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[localItemsLock lock];
			id item = [self itemFromLocalWithID:itemID];
			[localItemsLock unlock];
			
			if(item)
				[cache setObject:item forKey:itemID]; //更新内存缓存
			
			if(item==nil || [self isItemExpired:item])//本地没有item，或者本地item已经过期
			{
				if(item==nil && callback) //本地没有item，需要注册回调，在获取到最新数据后调用（通知调用者）。
					[self createRequestWithItemID:itemID registerCallback:callback];
				else
					[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
			}
			
			if(item && callback) //本地有item，异步调用finishedBlock（通知调用者）
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					callback(item, nil);
				});
			}
		});
	}
	else if([self isItemExpired:item]) //内存item已经过期
	{
		[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
	}
	
	if(item && callback) //本地有缓存，异步调用finishedBlock（通知调用者）
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			callback(item, nil);
		});
	}
}

- (id)itemWithID:(id)itemID callback:(void (^)(id item, NSError* error))callback
{
	NSAssert(itemID, @"%s: 参数itemID不可为nil", __FUNCTION__);
	
	id item;
	item = [cache objectForKey:itemID];
	if(item==nil)//内存中没有item
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[localItemsLock lock];
			id item = [self itemFromLocalWithID:itemID];
			[localItemsLock unlock];
			
			if(item)
				[cache setObject:item forKey:itemID]; //更新内存缓存
			
			if(item==nil || [self isItemExpired:item])//本地没有item，或者本地item已经过期
			{
				if(item==nil && callback) //本地没有item，需要注册回调，在获取到最新数据后调用（通知调用者）。
					[self createRequestWithItemID:itemID registerCallback:callback];
				else
					[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
			}
			
			if(item && callback) //本地有item，异步调用finishedBlock（通知调用者）
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					callback(item, nil);
				});
			}
		});
	}
	else if([self isItemExpired:item]) //内存item已经过期
	{
		[self createRequestWithItemID:itemID registerCallback:nil]; //从服务器获取最新信息
	}

	return item;
}

- (void)forceReloadItems:(NSArray*)itemIds
{
	@synchronized(self)//锁住请求队列
	{
		for (id itemID in itemIds) {
			IDNItemCenterRequest* request = dicRequests[itemID];
			if(request==nil)
			{
				request = [IDNItemCenterRequest new];
				request.itemID = itemID;
				dicRequests[itemID] = request;
				
				[self setNeedsSendRequests:YES];
			}
		}
	}
}

// 根据itemID创建请求，如果该请求已存在，不会重复创建。可能会在任意线程被调用
- (void)createRequestWithItemID:(id)itemID registerCallback:(void (^)(id item, NSError* error))callback
{
	if(itemID==nil)
		return;
	IDNItemCenterRequest* request;
	@synchronized(self)//锁住请求队列
	{
		request = dicRequests[itemID];
		if(request==nil)
		{
			request = [IDNItemCenterRequest new];
			request.itemID = itemID;
			dicRequests[itemID] = request;
			
			if(_combineRequests)
				[self setNeedsSendRequests:YES];
			else
			{
				request.sended = YES;
				[self sendRequests:@[itemID]];
			}
		}
		[request registerFinishCallback:callback];
	}
}

- (void)setNeedsSendRequests:(BOOL)needsSynchronize
{
	if(needsSynchronize==_needsSendRequests)
		return;
	_needsSendRequests = needsSynchronize;
	if(needsSynchronize==YES)
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			
			[sself batchSendRequests];
		});
	}
}

// 检测所有未发送的Requests，合并请求。总是在主线程调用，每次RunLoop调用一次
- (void)batchSendRequests
{
	NSMutableArray* requestIDs = [NSMutableArray new];
	NSInteger count = 0;
	@synchronized(self)//锁住请求队列
	{
		for (IDNItemCenterRequest*request in dicRequests.allValues) {
			if(request.sended) //请求已经发送过了
				continue;
			count++;
			if(count>20)
				break;
			
			request.sended = YES;
			[requestIDs addObject:request.itemID];
			NSLog(@"request UID=%@", request.itemID);
		}
		self.needsSendRequests = NO;
		if(count>20) // 请求还没有提交完，再发一次
			self.needsSendRequests = YES;
	}
	if(count)
	{
		[self sendRequests:requestIDs];
	}
}

- (void)sendRequests:(NSArray*)itemIDs
{
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		__typeof(self) sself = wself;
		[sself fetchItemsFromServerWithIDs:itemIDs callback:^(NSDictionary *dicItems, NSError *error) {
			if(error==nil && dicItems && [dicItems isKindOfClass:[NSDictionary class]]==NO)
			{
				NSString* errstr = [NSString stringWithFormat:@"[%@ fetchItemsFromServerWithIDs:callback:]回调返回的参数dicItems不是字典，而是%@", NSStringFromClass(self.class), NSStringFromClass(dicItems.class)];
				error = [NSError errorDescription:errstr];
				dicItems = nil;
			}
			// 本Block在哪个线程被调用是不确定的，是由子类的具体实现决定的
			__typeof(self) sself = wself;
			[sself didReceiveItems:dicItems ids:itemIDs error:error];
		}];
	});
}

// 本函数在哪个线程被调用是不确定的
- (void)didReceiveItems:(NSDictionary*)dicItems ids:(NSArray*)ids error:(NSError*)error
{
	if([NSThread currentThread]==[NSThread mainThread])//当前线程是主线程
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self didReceiveItemsOnBackground:dicItems ids:ids error:error];
		});
	}
	else
	{
		[self didReceiveItemsOnBackground:dicItems ids:ids error:error];
	}
}

// 本函数总是在后台线程被调用
- (void)didReceiveItemsOnBackground:(NSDictionary*)dicItems ids:(NSArray*)ids error:(NSError*)error
{
	if(dicItems.count)
	{//更新本地缓存
		[self checkAndUpdateLocalItemsOnBackground:dicItems.allValues ignoreObserver:nil];
	}
	
	NSMutableArray* requests = [NSMutableArray new];
	@synchronized(self)//锁住请求队列
	{
		if(error)
		{
			for (id itemID in ids) {
				IDNItemCenterRequest* request = dicRequests[itemID];
				request.error = error;
				request.retItem = nil;
				[requests addObject:request];
			}
		}
		else
		{
			NSMutableArray* mutableIDs = [ids mutableCopy];
			for (id itemID in dicItems.allKeys) {
				IDNItemCenterRequest* request = dicRequests[itemID];
				request.error = nil;
				request.retItem = dicItems[itemID];
				[requests addObject:request];
				[mutableIDs removeObject:itemID];
			}
			// 可能有的ID不存在，有的存在。
			for (id itemID in mutableIDs) {
				IDNItemCenterRequest* request = dicRequests[itemID];
				request.error = [NSError errorDescription:[NSString stringWithFormat:@"ID%@不存在", itemID]];
				request.retItem = nil;
				[requests addObject:request];
			}
		}
		[dicRequests removeObjectsForKeys:ids];
	}
	
	if(requests.count)
	{//调用callBacks，总是在主线程通知
		dispatch_async(dispatch_get_main_queue(), ^{
			for (IDNItemCenterRequest* request in requests) {
				[request finishCallbacks];
			}
		});
	}
}

- (void)checkAndUpdateLocalItems:(NSArray*)items
{
	[self checkAndUpdateLocalItems:items ignoreObserver:nil];
}
// 可在任意线程调用
- (void)checkAndUpdateLocalItems:(NSArray*)items ignoreObserver:(id<IDNItemCenterObserver>)ignoreObserver
{
	if(items==nil)
		return;
#ifdef DEBUG
	if([items isKindOfClass:[NSArray class]]==NO)
	{
		NSLog(@"%s: 参数items不是NSArray，而是%@", __FUNCTION__, NSStringFromClass([items class]));
		return;
	}
#endif
	if(items.count==0)
		return;
	if([NSThread currentThread]==[NSThread mainThread])//当前线程是主线程
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self checkAndUpdateLocalItemsOnBackground:items ignoreObserver:ignoreObserver];
		});
	}
	else
	{
		[self checkAndUpdateLocalItemsOnBackground:items ignoreObserver:ignoreObserver];
	}
}

// 总是在后台线程调用
- (void)checkAndUpdateLocalItemsOnBackground:(NSArray*)items ignoreObserver:(id<IDNItemCenterObserver>)ignoreObserver //items.count不可为0
{
	// 获取需要比对的所有IDs
	NSMutableArray* ids = [NSMutableArray new];
	for (id item in items) {
		@try {
			[ids addObject:[self idOfItem:item]];
		}
		@catch (NSException *exception) {
			NSLog(@"Exception - [%@ idOfItem:]: %@", NSStringFromClass(self.class), exception);
			return;
		}
	}
	
	[localItemsLock lock];
	
	// 获取需要比对的本地Items
	NSDictionary* dicLocalItems = [self itemsFromLocalWithIDs:ids]; // ***读取本地Items***
#ifdef DEBUG
	if(dicLocalItems && [dicLocalItems isKindOfClass:[NSDictionary class]]==NO)
	{
		NSString* errstr = [NSString stringWithFormat:@"[%@ fetchItemsFromServerWithIDs:callback:]回调返回的参数dicItems不是字典，而是%@", NSStringFromClass(self.class), NSStringFromClass(dicLocalItems.class)];
		NSLog(@"%@", errstr);
		dicLocalItems = nil;
	}
#endif
	// 检测需要更新的Items
	NSMutableArray* updateItems = [NSMutableArray new];
	for (NSInteger i = 0; i<items.count; i++) {
		id ID = ids[i];
		id item = items[i];
		id localItem = dicLocalItems[ID];
		if(localItem==nil || //本地没有缓存信息
		   [self isItemModified:localItem newItem:item]) //信息被修改过了，本地缓存信息失效
		{
			[updateItems addObject:item];
			[cache setObject:item forKey:ID];
		}
	}
	
	if(updateItems.count)//有Items需要更新
	{
		[self updateLocalItems:updateItems]; // ***写入本地Items***
		[localItemsLock unlock];
		
		// 通知观察者Item被更新
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself notifyObserversWithUpdatedItems:updateItems ignoreObserver:ignoreObserver];
		});
	}
	else
		[localItemsLock unlock];
}

- (void)localQueryWithParams:(NSDictionary*)params callback:(void (^)(NSArray* items))callback
{
	if(callback==nil)
		return;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[localItemsLock lock];
		NSArray* items = [self queryItemsFromLocalWithParams:params];
		[localItemsLock unlock];
#ifdef DEBUG
		if(items && [items isKindOfClass:[NSArray class]]==NO)
		{
			NSString* errstr = [NSString stringWithFormat:@"[%@ fetchItemsFromServerWithIDs:callback:]回调返回的参数dicItems不是NSArray，而是%@", NSStringFromClass(self.class), NSStringFromClass(items.class)];
			NSLog(@"%@", errstr);
			items = nil;
		}
#endif
		callback(items);
	});
}

- (NSUInteger)memoryCacheCountLimit
{
	return cache.countLimit;
}

- (void)setMemoryCacheCountLimit:(NSUInteger)memoryCacheCountLimit
{
	cache.countLimit = memoryCacheCountLimit;
}

#pragma mark Observers

- (void)addItemUpdatedObserver:(id<IDNItemCenterObserver>)observer
{
	@synchronized(observers)
	{
		if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
			return;
		if([observer respondsToSelector:@selector(itemCenter:updatedItem:)]==NO)//观察者没有实现指定方法
			return;
		[observers addPointer:(__bridge void *)(observer)];
	}
}
- (void)delItemUpdatedObserver:(id<IDNItemCenterObserver>)observer
{
	@synchronized(observers)
	{
		[observers removePointerIdentically:(__bridge void *)(observer)];
	}
}

- (void)notifyObserversWithUpdatedItems:(NSArray*)items ignoreObserver:(id<IDNItemCenterObserver>)ignoreObserver
{
	BOOL needsCompact = NO;
	// 将当前所有观察者保存到noteObservers中，以免观察者在通知方法- (void)itemCenter:updatedItem:里添加或者删除观察者造成死锁
	NSMutableArray* noteObservers = [NSMutableArray new];
	@synchronized(observers)
	{
		for (id<IDNItemCenterObserver> observer in observers) {
			if(observer==nil)
			{
				needsCompact = YES;
				continue;
			}
			if(observer!=ignoreObserver)
				[noteObservers addObject:observer];
		}
		[observers compact];
	}
	
	for (id<IDNItemCenterObserver> observer in noteObservers) {
		for (id item in items) {
			[observer itemCenter:self updatedItem:item];
		}
	}
}

#pragma mark overload methods 需要重载的方法

// 此函数需要加锁
// 执行本地查询。如果有的ID有，有的ID没有，那么只返回本地有的Items
- (NSDictionary*)itemsFromLocalWithIDs:(NSArray*)ids
{
	@throw @"子类应该重载此方法";
	return nil;
}

// 此函数需要加锁
// 执行本地自定义查询
- (NSArray*)queryItemsFromLocalWithParams:(NSDictionary*)params
{
	@throw @"子类应该重载此方法";
	return nil;
}

// 此函数需要加锁
- (void)updateLocalItems:(NSArray*)items
{
	@throw @"子类应该重载此方法";
}

//Item是否过期（需要重新从服务器获取），一般根据最近同步时间来确定
- (BOOL)isItemExpired:(id)item
{
	@throw @"子类应该重载此方法";
	return FALSE;
}

// 比较同ID的新旧两个对象是否被修改过
- (BOOL)isItemModified:(id)oldItem newItem:(id)newItem
{
	@throw @"子类应该重载此方法";
	return NO;
}

- (id)idOfItem:(id)item
{
	@throw @"子类应该重载此方法";
	return nil;
}

////同步从服务器获取Items
//+ (id)itemFromServerWithID:(id)itemID error:(NSError**)error
//{
//	@throw @"子类应该重载此方法";
//}

// 此函数总是在后台线程中被调用。异步从服务器获取Items，同步异步二选一
- (void)fetchItemsFromServerWithIDs:(NSArray*)itemIDs callback:(void (^)(NSDictionary* dicItems, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

@end
