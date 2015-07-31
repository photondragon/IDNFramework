//
//  IDNFixedList.m
//

#import "IDNFixedList.h"
#import "NSPointerArray+IDNExtend.h"

@interface IDNFixedList()
@property(nonatomic) BOOL needsSave;
@end

@implementation IDNFixedList
{
	NSArray* inmutablelist; //固定列表。是对listIDs的拷贝。主要是考虑多线程的问题，在读取列表内容的同时，后台可能会修改列表。每当列表被修改时，inmutablelist会设为nil，然后当访问list属性时，会重新生成inmutablelist
	NSMutableArray* listIDs;
	
	BOOL loadingHead;
	BOOL loadingTail;
	NSMutableArray* headFinishedBlocks;
	NSMutableArray* tailFinishedBlocks;

	NSPointerArray* observers;
	
	NSMutableDictionary* persistDict;
}

- (instancetype)initWithPersistFilePath:(NSString *)persistFilePath
{
	self = [super init];
	if (self) {
		_persistFilePath = [persistFilePath copy];
		if([[NSFileManager defaultManager] fileExistsAtPath:_persistFilePath])
		{
			persistDict = [NSKeyedUnarchiver unarchiveObjectWithFile:_persistFilePath];
			if(persistDict[@"list"] && persistDict[@"custom"])
				listIDs = persistDict[@"list"];
			else //无效的文件。
				persistDict = nil;
		}
		if(persistDict==nil)
		{
			listIDs = [NSMutableArray new];
			persistDict = [NSMutableDictionary new];
			persistDict[@"custom"] = [NSMutableDictionary new];
			persistDict[@"list"] = listIDs;
		}
		
		headFinishedBlocks = [NSMutableArray new];
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
			inmutablelist = [listIDs copy];
		}
		return inmutablelist;
	}
}

- (void)refreshWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	id headID;
	@synchronized(self)
	{
		if(finishedBlock)
			[headFinishedBlocks addObject:finishedBlock];
		
		if(loadingHead)
			return;
		
		loadingHead = YES;
		
		headID = [listIDs firstObject];
		if(headID==nil) //如果是首次加载，转为调用more
		{
			[self moreWithFinishedBlock:nil];
			return;
		}
	}
	
	// 异步发送loadHead请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryBeforeHeadID:headID callback:^(NSArray *ids, BOOL needsReload, NSError *error) {
			__typeof(self) sself = wself;
			[sself preposeIDs:ids needsReload:needsReload error:error];
		}];
	});
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	id tailID;
	@synchronized(self)
	{
		if(finishedBlock)
			[tailFinishedBlocks addObject:finishedBlock];
		
		if(loadingTail)
			return;
		
		loadingTail = YES;
		
		tailID = [listIDs lastObject];
	}
	
	// 异步发送loadTail请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryAfterTailID:tailID callback:^(NSArray *ids, BOOL reachEnd, NSError *error) {
			if(error)
				return;
			__typeof(self) sself = wself;
			[sself appendIDs:ids reachEnd:reachEnd error:error queryTailID:tailID];
		}];
	});
}

- (void)preposeIDs:(NSArray*)ids needsReload:(BOOL)needsReload error:(NSError*)error
{
	// 保证preposeIDsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self preposeIDsOnMainThread:ids needsReload:needsReload error:error];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself preposeIDsOnMainThread:ids needsReload:needsReload error:error];
		});
	}
}

// 在主线程进行列表修改，同时发送列表修改通知和finishedBlock调用。这三步必须连接调用，不可打断。因为加载列表头和加载列表尾可同时进行，如果这三步可拆分，可能会出现调用顺序混乱，导致列表修改通知不正确。
- (void)preposeIDsOnMainThread:(NSArray*)ids needsReload:(BOOL)needsReload error:(NSError*)error
{
	NSMutableArray* added = [NSMutableArray new];
	NSMutableArray* deleted = [NSMutableArray new];
	NSArray* finishedBlocks;
	@synchronized(self)
	{
		if(error==nil)
		{
			if(needsReload)
			{
				for(NSInteger i = 0; i<listIDs.count; i++)
				{
					[deleted addObject:@(i)];
				}
				[listIDs removeAllObjects];
				inmutablelist = nil;
				self.needsSave = YES;
				
				_reachEnd = NO;
				if(ids.count)
					[listIDs addObjectsFromArray:ids];
			}
			else if(ids.count)
			{
				[listIDs replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:ids];
				inmutablelist = nil;
				self.needsSave = YES;
			}
			
			for (NSInteger i = 0; i<ids.count; i++)
			{
				[added addObject:@(i)];
			}
		}
		
		loadingHead = NO;
		finishedBlocks = [headFinishedBlocks copy];
		[headFinishedBlocks removeAllObjects];
	}
	
	if(added.count || deleted.count)
		[self notifyObserversOnMainThreadWithDeleted:deleted added:added modified:nil];
	
	if(finishedBlocks.count)
		[self notifyFinishedBlocksOnMainThread:finishedBlocks error:error];
}

- (void)appendIDs:(NSArray*)ids reachEnd:(BOOL)reachEnd error:(NSError*)error queryTailID:(id)queryTailID
{
	// 保证preposeIDsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self appendIDsOnMainThread:ids reachEnd:reachEnd error:error queryTailID:queryTailID];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself appendIDsOnMainThread:ids reachEnd:reachEnd error:error queryTailID:queryTailID];
		});
	}
}

// queryTailID用于检测这次Query是否被取消。
- (void)appendIDsOnMainThread:(NSArray*)ids reachEnd:(BOOL)reachEnd error:(NSError*)error queryTailID:(id)queryTailID
{
	NSMutableArray* added = nil;
	NSMutableArray* deleted = nil;
	NSArray* headFinished = nil;
	NSArray* tailFinished;
	@synchronized(self)
	{
		if(queryTailID == [listIDs lastObject] && //如果queryTailID与当前tailID不一样，说明列表经过一次reload，本次queryTail被取消了。
		   error==nil && ids.count)
		{
			added = [NSMutableArray new];
			deleted = [NSMutableArray new];
			
			NSInteger prevCount = listIDs.count;
			for (NSInteger i = 0; i<ids.count; i++)
			{
				[added addObject:@(i+prevCount)];
			}
			
			[listIDs addObjectsFromArray:ids];
			inmutablelist = nil;
			self.needsSave = YES;
		}
		
		if(queryTailID==nil && loadingHead)//首次加载，是由refresh方法发起的
		{
			loadingHead = NO;
			headFinished = [headFinishedBlocks copy];
			[headFinishedBlocks removeAllObjects];
		}
		
		if(reachEnd)
			_reachEnd = YES;
		
		loadingTail = NO;
		tailFinished = [tailFinishedBlocks copy];
		[tailFinishedBlocks removeAllObjects];
	}
	
	if(added.count || deleted.count)
		[self notifyObserversOnMainThreadWithDeleted:deleted added:added modified:@[]];
	
	if(headFinished.count)
		[self notifyFinishedBlocksOnMainThread:headFinished error:error];
	
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

- (void)addFixedListObserver:(id<IDNFixedListObserver>)observer
{
	if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
		return;
	if([observer respondsToSelector:@selector(fixedList:deletedIndics:addedIndics:modifiedIndics:)]==NO)//观察者没有实现指定方法
		return;
	[observers addPointer:(__bridge void *)(observer)];
}
- (void)delFixedListObserver:(id<IDNFixedListObserver>)observer
{
	[observers removePointerIdentically:(__bridge void *)(observer)];
}

- (void)notifyObserversOnMainThreadWithDeleted:(NSArray*)deleted added:(NSArray*)added modified:(NSArray*)modified
{
	BOOL needsCompact = NO;
	for (id<IDNFixedListObserver> observer in observers) {
		if(observer==nil)
		{
			needsCompact = YES;
			continue;
		}
		[observer fixedList:self deletedIndics:deleted addedIndics:added modifiedIndics:modified];
	}
	[observers compact];
}

#pragma mark 需要重载的方法

// callback必须要被调用，否则会永远处于loadingTail状态。tailID==nil表示首次调用，获取列表第一段。
- (void)queryAfterTailID:(id)tailID callback:(void (^)(NSArray* ids, BOOL reachEnd, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

// callback必须要被调用，否则会永远处于loadingHead状态。headID不可能为nil
- (void)queryBeforeHeadID:(id)headID callback:(void (^)(NSArray* ids, BOOL needsReload, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

@end
