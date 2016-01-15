//
//  IDNListItemCenter.m
//  testItemCenter
//
//  Created by photondragon on 15/7/18.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNListItemCenter.h"
#import "NSPointerArray+IDNExtend.h"
#import "NSError+IDNExtend.h"

@interface IDNListItemCenterRequest : NSObject
@property(nonatomic,strong) id itemID;
@property(nonatomic) BOOL sended; // 请求是否已经发出
@property(nonatomic,strong) id retItem; //返回的对象
@property(nonatomic,strong) NSError* error;
@end
@implementation IDNListItemCenterRequest
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

@interface IDNListItemCenter()

@property(nonatomic) BOOL requesting; //是否正在向服务器请求数据

@end

@implementation IDNListItemCenter
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

- (void)forceReload
{
	@synchronized(self)//锁住请求队列
	{
		[self sendRequest];
	}
}

// 根据itemID创建请求，如果该请求已存在，不会重复创建。可能会在任意线程被调用
- (void)createRequestWithItemID:(id)itemID registerCallback:(void (^)(id item, NSError* error))callback
{
	if(itemID==nil)
		return;
	IDNListItemCenterRequest* request;
	@synchronized(self)//锁住请求队列
	{
		request = dicRequests[itemID];
		if(request==nil)
		{
			request = [IDNListItemCenterRequest new];
			request.itemID = itemID;
			request.sended = YES;
			dicRequests[itemID] = request;

			[self sendRequest];
		}
		[request registerFinishCallback:callback];
	}
}

- (void)sendRequest
{
	if(self.requesting)
		return;
	self.requesting = YES;
	
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		__typeof(self) sself = wself;
		[sself fetchItemsFromServerWithCallback:^(NSDictionary *dicItems, NSError *error) {
			if(error==nil && dicItems && [dicItems isKindOfClass:[NSDictionary class]]==NO)
			{
				NSString* errstr = [NSString stringWithFormat:@"[%@ fetchItemsFromServerWithIDs:callback:]回调返回的参数dicItems不是字典，而是%@", NSStringFromClass(self.class), NSStringFromClass(dicItems.class)];
				error = [NSError errorDescription:errstr];
				dicItems = nil;
			}
			// 本Block在哪个线程被调用是不确定的，是由子类的具体实现决定的
			__typeof(self) sself = wself;
			[sself didReceiveItems:dicItems error:error];
		}];
	});
}

// 本函数在哪个线程被调用是不确定的
- (void)didReceiveItems:(NSDictionary*)dicItems error:(NSError*)error
{
	if([NSThread currentThread]==[NSThread mainThread])//当前线程是主线程
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self didReceiveItemsOnBackground:dicItems error:error];
		});
	}
	else
	{
		[self didReceiveItemsOnBackground:dicItems error:error];
	}
}

// 本函数总是在后台线程被调用
- (void)didReceiveItemsOnBackground:(NSDictionary*)dicItems error:(NSError*)error
{
	if(dicItems.count)
	{//更新本地缓存
		[self saveAllLocalItemsOnBackground:dicItems.allValues];
	}
	
	NSArray* requests;
	@synchronized(self)//锁住请求队列
	{
		if(error)
		{
			for (id itemID in dicRequests.allKeys) {
				IDNListItemCenterRequest* request = dicRequests[itemID];
				request.error = error;
				request.retItem = nil;
			}
		}
		else
		{
			for (id itemID in dicRequests.allKeys) {
				IDNListItemCenterRequest* request = dicRequests[itemID];
				id item = dicItems[itemID];
				if(item)
				{
					request.error = nil;
					request.retItem = item;
				}
				else
				{
					request.error = [NSError errorDescription:[NSString stringWithFormat:@"ID%@不存在", itemID]];
					request.retItem = nil;
				}
			}
		}
		requests = dicRequests.allValues;
		[dicRequests removeAllObjects];
		
		self.requesting = NO;
	}
	
	if(requests.count)
	{//调用callBacks，总是在主线程通知
		dispatch_async(dispatch_get_main_queue(), ^{
			for (IDNListItemCenterRequest* request in requests) {
				[request finishCallbacks];
			}
		});
	}
}

// 总是在后台线程调用
- (void)saveAllLocalItemsOnBackground:(NSArray*)items //items.count不可为0
{
	if(items.count==0)
		return;
	[localItemsLock lock];
	[self clearAllLocalItems]; // ***清空本地Items***
	[self updateLocalItems:items]; // ***写入本地Items***
	[localItemsLock unlock];
	
	//更新内存缓存
	[cache removeAllObjects];
	for (id item in items) {
		[cache setObject:item forKey:[self idOfItem:item]];
	}

	// 通知观察者Item被更新
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		__typeof(self) sself = wself;
		[sself notifyObserversWithUpdatedItems:items];
	});

}

- (void)deleteItemsWithIDs:(NSArray*)itemIDs
{
	if(itemIDs==nil)
		return;
#ifdef DEBUG
	if([itemIDs isKindOfClass:[NSArray class]]==NO)
	{
		NSLog(@"%s: 参数itemIDs不是NSArray，而是%@", __FUNCTION__, NSStringFromClass([itemIDs class]));
		return;
	}
#endif
	if(itemIDs.count==0)
		return;
	if([NSThread currentThread]==[NSThread mainThread])//当前线程是主线程
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self deleteItemsWithIDsOnBackground:itemIDs];
		});
	}
	else
	{
		[self deleteItemsWithIDsOnBackground:itemIDs];
	}
	
}

// 总是在后台线程调用
- (void)deleteItemsWithIDsOnBackground:(NSArray*)itemIDs //itemIDs.count不可为0
{
	[localItemsLock lock];
	[self deleteLocalItemWithItemIDs:itemIDs]; // ***删除本地Items***
	[localItemsLock unlock];
	
	//	// 通知观察者Item被更新
	//	__weak __typeof(self) wself = self;
	//	dispatch_async(dispatch_get_main_queue(), ^{
	//		__typeof(self) sself = wself;
	//		[sself notifyObserversWithUpdatedItems:updateItems];
	//	});
}

// 可在任意线程调用
- (void)checkAndUpdateLocalItems:(NSArray*)items
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
			[self checkAndUpdateLocalItemsOnBackground:items];
		});
	}
	else
	{
		[self checkAndUpdateLocalItemsOnBackground:items];
	}
}

// 总是在后台线程调用
- (void)checkAndUpdateLocalItemsOnBackground:(NSArray*)items //items.count不可为0
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
			[sself notifyObserversWithUpdatedItems:updateItems];
		});
	}
	else
		[localItemsLock unlock];
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

- (void)addItemUpdatedObserver:(id<IDNListItemCenterObserver>)observer
{
	@synchronized(observers)
	{
		if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
			return;
		if([observer respondsToSelector:@selector(listItemCenter:updatedItem:)]==NO)//观察者没有实现指定方法
			return;
		[observers addPointer:(__bridge void *)(observer)];
	}
}
- (void)delItemUpdatedObserver:(id<IDNListItemCenterObserver>)observer
{
	@synchronized(observers)
	{
		[observers removePointerIdentically:(__bridge void *)(observer)];
	}
}

- (void)notifyObserversWithUpdatedItems:(NSArray*)items
{
	BOOL needsCompact = NO;
	// 将当前所有观察者保存到noteObservers中，以免观察者在通知方法- (void)itemCenter:updatedItem:里添加或者删除观察者造成死锁
	NSMutableArray* noteObservers = [NSMutableArray new];
	@synchronized(observers)
	{
		for (id<IDNListItemCenterObserver> observer in observers) {
			if(observer==nil)
			{
				needsCompact = YES;
				continue;
			}
			[noteObservers addObject:observer];
		}
		[observers compact];
	}
	
	for (id<IDNListItemCenterObserver> observer in noteObservers) {
		for (id item in items) {
			[observer listItemCenter:self updatedItem:item];
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
- (void)clearAllLocalItems
{
	@throw @"子类应该重载此方法";
}

- (void)updateLocalItems:(NSArray*)items
{
	@throw @"子类应该重载此方法";
}

- (void)deleteLocalItemWithItemIDs:(NSArray*)itemIDs
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

// 此函数总是在后台线程中被调用。异步从服务器获取Items，同步异步二选一
- (void)fetchItemsFromServerWithCallback:(void (^)(NSDictionary* dicItems, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

@end
