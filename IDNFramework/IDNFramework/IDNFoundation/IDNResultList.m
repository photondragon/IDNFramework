//
//  IDNResultList.m
//

#import "IDNResultList.h"
#import "NSPointerArray+IDNExtend.h"

#define DefaultSegmentLength 20

@interface IDNResultList()

@property(nonatomic) BOOL needsSave;

@end

@implementation IDNResultList
{
	NSArray* inmutablelist; //固定列表。是对listRecords的拷贝。主要是考虑多线程的问题，在读取列表内容的同时，后台可能会修改列表。每当列表被修改时，inmutablelist会设为nil，然后当访问list属性时，会重新生成inmutablelist
	NSMutableArray* listRecords;
	NSArray* listResultIDs; // 为nil表示没有查询过
	NSArray* tempResultIDs;
	
	BOOL isReloading; //是否正在查询（获取查询结果IDs数组）
	NSInteger currentReloadCounts; //查询次数（不是分段加载的次数）
	
	BOOL loadingMore;
	NSMutableArray* tailFinishedBlocks;

	NSPointerArray* observers;
	
	NSMutableDictionary* persistDict;
}

- (instancetype)initWithPersistFilePath:(NSString *)persistFilePath
{
	self = [super init];
	if (self) {
		_segmentLength = DefaultSegmentLength;
		_persistFilePath = [persistFilePath copy];
		if([[NSFileManager defaultManager] fileExistsAtPath:_persistFilePath])
		{
			persistDict = [NSKeyedUnarchiver unarchiveObjectWithFile:_persistFilePath];
			if(persistDict[@"list"] && persistDict[@"custom"])
			{
				listRecords = persistDict[@"list"];
				listResultIDs = persistDict[@"resultIDs"];
			}
			else //无效的文件。
				persistDict = nil;
		}
		if(persistDict==nil)
		{
			listRecords = [NSMutableArray new];
			persistDict = [NSMutableDictionary new];
			persistDict[@"custom"] = [NSMutableDictionary new];
			persistDict[@"list"] = listRecords;
		}
		
		tailFinishedBlocks = [NSMutableArray new];
		observers = [NSPointerArray weakObjectsPointerArray];
	}
	return self;
}

- (instancetype)init
{
	return [self initWithPersistFilePath:nil];
}

- (NSArray*)list{
	@synchronized(self)
	{
		if (inmutablelist==nil) {
			inmutablelist = [listRecords copy];
		}
		return inmutablelist;
	}
}

- (BOOL)reachEnd
{
	@synchronized(self)
	{
		if(listResultIDs) //有查询结果
			return listRecords.count == listResultIDs.count;
	}
	return NO;
}
- (void)reloadWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	NSArray* cancelledCallbacks = nil;
	@synchronized(self)
	{
		if(finishedBlock)
			[tailFinishedBlocks addObject:finishedBlock];
		
		if(isReloading)
			return;
		isReloading = YES;
		
		currentReloadCounts++;

		if(loadingMore) // 在load more的过程中reload
		{
			if (tailFinishedBlocks.count) {
				cancelledCallbacks = [tailFinishedBlocks copy];
				[tailFinishedBlocks removeAllObjects];
			}
		}
		else
			loadingMore = YES;
	}
	
	if(cancelledCallbacks)
	{
		[self notifyFinishedBlocksOnMainThread:cancelledCallbacks error:[NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:@"操作取消"}]];
	}
	
	// 异步发送loadHead请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryResultWithCallback:^(NSArray* resultIDs, NSError* error){
			__typeof(self) sself = wself;
			[sself receiveResultIDs:resultIDs error:error];
		}];
	});
}

- (void)receiveResultIDs:(NSArray*)resultIDs error:(NSError*)error
{
	if([NSThread currentThread] == [NSThread mainThread])
	{
		[self receiveResultIDsOnMainThread:resultIDs error:error];
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self receiveResultIDsOnMainThread:resultIDs error:error];
		});
	}
}

- (void)receiveResultIDsOnMainThread:(NSArray*)resultIDs error:(NSError*)error
{
	NSInteger reloadCounts = 0;
	NSArray* callbacks = nil;
	NSArray* queryIDs = nil;
	NSMutableArray* deleted = nil;
	
	@synchronized(self)
	{
		if(error)
		{
			if(tailFinishedBlocks.count)
			{
				callbacks = [tailFinishedBlocks copy];
				[tailFinishedBlocks removeAllObjects];
			}
			isReloading = NO;
			loadingMore = NO;
		}
		else
		{
			if(resultIDs.count)
			{
				tempResultIDs = resultIDs;
				
				NSInteger count = _segmentLength;
				if(count>resultIDs.count)
					count = resultIDs.count;
				queryIDs = [resultIDs subarrayWithRange:NSMakeRange(0, count)];
				
				reloadCounts = currentReloadCounts;
			}
			else // 查询结果个数为0
			{
				if(listRecords.count)
				{
					deleted = [NSMutableArray new];
					for (NSInteger i = 0; i<listRecords.count; i++) {
						[deleted addObject:@(i)];
					}
					[listRecords removeAllObjects];
					inmutablelist = nil;
				}
				
				listResultIDs = [NSArray new];
				persistDict[@"resultIDs"] = listResultIDs;
				
				isReloading = NO;
				loadingMore = NO;
				
				callbacks = [tailFinishedBlocks copy];
				[tailFinishedBlocks removeAllObjects];
				
				self.needsSave = YES;
			}
		}
	}
	
	if(callbacks)
	{
		[self notifyFinishedBlocksOnMainThread:callbacks error:error];
		return;
	}
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self queryRecordsWithIDs:queryIDs callback:^(NSArray *records, NSError *error) {
				__typeof(self) sself = wself;
				
				[sself appendRecords:records queryIDs:queryIDs error:error reloadCounts:reloadCounts];
			}];
		});
	}
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	NSArray* queryIDs = nil;
	NSInteger reloadCounts;
	@synchronized(self)
	{
		if(listResultIDs==nil)
		{
			[self reloadWithFinishedBlock:finishedBlock];
			return;
		}
		NSRange range = NSMakeRange(listRecords.count, _segmentLength);
		
		if(range.location >= listResultIDs.count) // 全部取完了
		{
			[self notifyFinishedBlocksOnMainThread:@[finishedBlock] error:[NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:@"已经到达列表末尾"}]];
			return;
		}
		
		if(finishedBlock)
			[tailFinishedBlocks addObject:finishedBlock];
		
		if(loadingMore)
			return;
		
		loadingMore = YES;
		
		if(range.location+range.length>listResultIDs.count)
			range.length = listResultIDs.count - range.location;
		queryIDs = [listResultIDs subarrayWithRange:range];
		
		reloadCounts = currentReloadCounts;
	}
	
	// 异步发送loadTail请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryRecordsWithIDs:queryIDs callback:^(NSArray *records, NSError *error) {
			__typeof(self) sself = wself;
			[sself appendRecords:records queryIDs:queryIDs error:error reloadCounts:reloadCounts];
		}];
	});
}

- (void)appendRecords:(NSArray*)records queryIDs:(NSArray*)queryIDs error:(NSError*)error reloadCounts:(NSInteger)reloadCounts
{
	// 保证preposeRecordsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self appendRecordsOnMainThread:records queryIDs:queryIDs error:error reloadCounts:reloadCounts];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself appendRecordsOnMainThread:records queryIDs:queryIDs error:error reloadCounts:reloadCounts];
		});
	}
}

// queryTailRecord用于检测这次Query是否被取消。
- (void)appendRecordsOnMainThread:(NSArray*)records queryIDs:(NSArray*)queryIDs error:(NSError*)error reloadCounts:(NSInteger)reloadCounts
{
	if(error==nil && records.count<queryIDs.count)
	{
		error = [NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:@"返回的数量和请求的数量不一致"}];
	}
	
	NSMutableArray* added = nil;
	NSMutableArray* deleted = nil;
	NSArray* tailFinished = nil;
	@synchronized(self)
	{
		if(reloadCounts != currentReloadCounts) //当前查询操作已经被取消
			return;
		
		if(error)
		{
			if(isReloading)
			{
				isReloading = NO;
				tempResultIDs = nil;
			}
		}
		else //error == nil
		{
			if(isReloading)
			{
				isReloading = NO;
				
				NSAssert1(tempResultIDs, @"%s: tempResultIDs为nil", __func__);
				listResultIDs = tempResultIDs;
				persistDict[@"resultIDs"] = listResultIDs;
				tempResultIDs = nil;
				
				if(listRecords.count)
				{
					deleted = [NSMutableArray new];
					for (NSInteger i = 0; i<listRecords.count; i++) {
						[deleted addObject:@(i)];
					}
					[listRecords removeAllObjects];
				}
			}
			
			if(records.count)
			{
				NSInteger oldCount = listRecords.count;
				added = [NSMutableArray new];
				for (NSInteger i = 0; i<records.count; i++) {
					[added addObject:@(oldCount+i)];
				}
				[listRecords addObjectsFromArray:records];
			}
			
			inmutablelist = nil;
			
			self.needsSave = YES;
		} //end error == nil
		
		loadingMore = NO;
		tailFinished = [tailFinishedBlocks copy];
		[tailFinishedBlocks removeAllObjects];
	}
	
	if(added.count || deleted.count)
		[self notifyObserversOnMainThreadWithModified:nil deleted:deleted added:added];
	
	if(tailFinished.count)
		[self notifyFinishedBlocksOnMainThread:tailFinished error:error];
}

- (void)notifyFinishedBlocksOnMainThread:(NSArray*)finishedBlocks error:(NSError*)error
{
	for (void (^finishedBlock)(NSError*error) in finishedBlocks) {
		finishedBlock(error);
	}
}

#pragma mark 持久化

- (void)setNeedsSave:(BOOL)needsSave
{
	@synchronized(self)
	{
		if(needsSave && _persistFilePath.length==0)
			needsSave = NO;
		if(_needsSave==needsSave)
			return;
		_needsSave = needsSave;
	}
	if(needsSave)
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			__typeof(self) sself = wself;
			[sself saveOnBackground];
		});
	}
}

- (void)saveOnBackground
{
	NSData* data;
	@synchronized(self)
	{
		_needsSave = NO;
		data = [NSKeyedArchiver archivedDataWithRootObject:persistDict];
	}
	[data writeToFile:_persistFilePath atomically:YES];
}
- (id)persistObjectForName:(NSString*)name
{
	if(name==nil)
		return nil;
	@synchronized(self)
	{
		return persistDict[@"custom"][name];
	}
}
- (void)setPersistObject:(id)object forName:(NSString*)name
{
	if(name==nil || object==nil)
		return;
	@synchronized(self)
	{
		persistDict[@"custom"][name] = object;
		self.needsSave = YES;
	}
}

#pragma mark Observers

- (void)addResultListObserver:(id<IDNResultListObserver>)observer
{
	if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
		return;
	if([observer respondsToSelector:@selector(resultList:modifiedIndics:deletedIndics:addedIndics:)]==NO)//观察者没有实现指定方法
		return;
	[observers addPointer:(__bridge void *)(observer)];
}
- (void)delResultListObserver:(id<IDNResultListObserver>)observer
{
	[observers removePointerIdentically:(__bridge void *)(observer)];
}

- (void)notifyObserversOnMainThreadWithModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added
{
	BOOL needsCompact = NO;
	for (id<IDNResultListObserver> observer in observers) {
		if(observer==nil)
		{
			needsCompact = YES;
			continue;
		}
		[observer resultList:self modifiedIndics:modified deletedIndics:deleted addedIndics:added];
	}
	[observers compact];
}

#pragma mark 需要重载的方法

- (void)queryResultWithCallback:(void (^)(NSArray* resultIDs, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

// callback必须要被调用，否则会永远处于loadingMore状态。
- (void)queryRecordsWithIDs:(NSArray*)ids callback:(void (^)(NSArray* records, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

@end
