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
	NSArray* inmutablelist; //固定列表。是对listRecords的拷贝。主要是考虑多线程的问题，在读取列表内容的同时，后台可能会修改列表。每当列表被修改时，inmutablelist会设为nil，然后当访问list属性时，会重新生成inmutablelist
	NSMutableArray* listRecords;
	
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
				listRecords = persistDict[@"list"];
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
			inmutablelist = [listRecords copy];
		}
		return inmutablelist;
	}
}

- (void)refreshWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	id headRecord;
	@synchronized(self)
	{
		if(finishedBlock)
			[headFinishedBlocks addObject:finishedBlock];
		
		if(loadingHead)
			return;
		
		loadingHead = YES;
		
		headRecord = [listRecords firstObject];
		if(headRecord==nil) //如果是首次加载，转为调用more
		{
			[self moreWithFinishedBlock:nil];
			return;
		}
	}
	
	// 异步发送loadHead请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryBeforeHeadRecord:headRecord callback:^(NSArray *records, BOOL needsReload, NSError *error) {
			__typeof(self) sself = wself;
			[sself preposeRecords:records needsReload:needsReload error:error];
		}];
	});
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	id tailRecord;
	@synchronized(self)
	{
		if(finishedBlock)
			[tailFinishedBlocks addObject:finishedBlock];
		
		if(loadingTail)
			return;
		
		loadingTail = YES;
		
		tailRecord = [listRecords lastObject];
	}
	
	// 异步发送loadTail请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryAfterTailRecord:tailRecord callback:^(NSArray *records, BOOL reachEnd, NSError *error) {
			__typeof(self) sself = wself;
			[sself appendRecords:records reachEnd:reachEnd error:error queryTailRecord:tailRecord];
		}];
	});
}

- (void)replaceRecord:(id)newRecord
{
	if(newRecord==nil)
		return;
	@synchronized(self)
	{
		for (NSInteger i=0;i<listRecords.count;i++) {
			id record = listRecords[i];
			if([self doesRecord:record hasSameIDWithRecord:newRecord]==YES)
			{
				[listRecords replaceObjectAtIndex:i withObject:newRecord];
				inmutablelist = nil;
				self.needsSave = YES;
				if([NSThread currentThread]==[NSThread mainThread])
					[self notifyObserversOnMainThreadWithModified:@[@(i)] deleted:nil added:nil];
				else
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self notifyObserversOnMainThreadWithModified:@[@(i)] deleted:nil added:nil];
					});
				}
				break;
			}
		}
	}
}

- (void)preposeRecords:(NSArray*)records needsReload:(BOOL)needsReload error:(NSError*)error
{
	// 保证preposeRecordsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self preposeRecordsOnMainThread:records needsReload:needsReload error:error];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself preposeRecordsOnMainThread:records needsReload:needsReload error:error];
		});
	}
}

// 在主线程进行列表修改，同时发送列表修改通知和finishedBlock调用。这三步必须连接调用，不可打断。因为加载列表头和加载列表尾可同时进行，如果这三步可拆分，可能会出现调用顺序混乱，导致列表修改通知不正确。
- (void)preposeRecordsOnMainThread:(NSArray*)records needsReload:(BOOL)needsReload error:(NSError*)error
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
				for(NSInteger i = 0; i<listRecords.count; i++)
				{
					[deleted addObject:@(i)];
				}
				[listRecords removeAllObjects];
				inmutablelist = nil;
				self.needsSave = YES;
				
				_reachEnd = NO;
				if(records.count)
					[listRecords addObjectsFromArray:records];
			}
			else if(records.count)
			{
				[listRecords replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:records];
				inmutablelist = nil;
				self.needsSave = YES;
			}
			
			for (NSInteger i = 0; i<records.count; i++)
			{
				[added addObject:@(i)];
			}
		}
		
		loadingHead = NO;
		finishedBlocks = [headFinishedBlocks copy];
		[headFinishedBlocks removeAllObjects];
	}
	
	if(added.count || deleted.count)
		[self notifyObserversOnMainThreadWithModified:nil deleted:deleted added:added];
	
	if(finishedBlocks.count)
		[self notifyFinishedBlocksOnMainThread:finishedBlocks error:error];
}

- (void)appendRecords:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error queryTailRecord:(id)queryTailRecord
{
	// 保证preposeRecordsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self appendRecordsOnMainThread:records reachEnd:reachEnd error:error queryTailRecord:queryTailRecord];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself appendRecordsOnMainThread:records reachEnd:reachEnd error:error queryTailRecord:queryTailRecord];
		});
	}
}

// queryTailRecord用于检测这次Query是否被取消。
- (void)appendRecordsOnMainThread:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error queryTailRecord:(id)queryTailRecord
{
	NSMutableArray* added = nil;
	NSMutableArray* deleted = nil;
	NSArray* headFinished = nil;
	NSArray* tailFinished;
	@synchronized(self)
	{
		if(queryTailRecord == [listRecords lastObject] && //如果queryTailRecord与当前tailRecord不一样，说明列表经过一次reload，本次queryTail被取消了。
		   error==nil && records.count)
		{
			added = [NSMutableArray new];
			deleted = [NSMutableArray new];
			
			NSInteger prevCount = listRecords.count;
			for (NSInteger i = 0; i<records.count; i++)
			{
				[added addObject:@(i+prevCount)];
			}
			
			[listRecords addObjectsFromArray:records];
			inmutablelist = nil;
			self.needsSave = YES;
		}
		
		if(queryTailRecord==nil && loadingHead)//首次加载，是由refresh方法发起的
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
		[self notifyObserversOnMainThreadWithModified:nil deleted:deleted added:added];
	
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
	if([observer respondsToSelector:@selector(fixedList:modifiedIndics:deletedIndics:addedIndics:)]==NO)//观察者没有实现指定方法
		return;
	[observers addPointer:(__bridge void *)(observer)];
}
- (void)delFixedListObserver:(id<IDNFixedListObserver>)observer
{
	[observers removePointerIdentically:(__bridge void *)(observer)];
}

- (void)notifyObserversOnMainThreadWithModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added
{
	BOOL needsCompact = NO;
	for (id<IDNFixedListObserver> observer in observers) {
		if(observer==nil)
		{
			needsCompact = YES;
			continue;
		}
		[observer fixedList:self modifiedIndics:modified deletedIndics:deleted addedIndics:added];
	}
	[observers compact];
}

#pragma mark 需要重载的方法

// callback必须要被调用，否则会永远处于loadingTail状态。tailRecord==nil表示首次调用，获取列表第一段。
- (void)queryAfterTailRecord:(id)tailRecord callback:(void (^)(NSArray* records, BOOL reachEnd, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

// callback必须要被调用，否则会永远处于loadingHead状态。headRecord不可能为nil
- (void)queryBeforeHeadRecord:(id)headRecord callback:(void (^)(NSArray* records, BOOL needsReload, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

- (BOOL)doesRecord:(id)record hasSameIDWithRecord:(id)anotherRecord
{
	@throw @"子类应该重载此方法";
}
@end
