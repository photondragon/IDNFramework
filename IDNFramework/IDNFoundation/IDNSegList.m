//
//  IDNSegList.m
//

#import "IDNSegList.h"
#import "NSPointerArray+IDNExtend.h"

#define DefaultSegmentLength 20

@interface IDNSegList()
@property(nonatomic) BOOL needsSave;
@end

@implementation IDNSegList
{
	NSArray* inmutablelist; //固定列表。是对listRecords的拷贝。主要是考虑多线程的问题，在读取列表内容的同时，后台可能会修改列表。每当列表被修改时，inmutablelist会设为nil，然后当访问list属性时，会重新生成inmutablelist
	NSMutableArray* listRecords;
	
	BOOL loadingHead;
	BOOL loadingTail;
	BOOL isReload; //在loadingHead时有效，区分是refresh还是reload。
	NSMutableArray* headFinishedBlocks;
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

- (void)reloadWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	NSInteger queryCount;
	@synchronized(self)
	{
		if(finishedBlock)
			[headFinishedBlocks addObject:finishedBlock];
		
		isReload = YES;
		if(loadingHead)
			return;
		
		loadingHead = YES;
		
		if(listRecords.count==0) //如果是首次加载，转为调用more
		{
			[self moreWithFinishedBlock:nil];
			return;
		}
		queryCount = _segmentLength;
	}
	
	// 异步发送loadHead请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryAfterRecord:nil count:queryCount callback:^(NSArray *records, BOOL reachEnd, NSError *error) {
			__typeof(self) sself = wself;
			[sself preposeRecords:records reachEnd:reachEnd error:error];
		}];
	});
}

- (void)refreshWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	NSInteger queryCount;
	@synchronized(self)
	{
		if(finishedBlock)
			[headFinishedBlocks addObject:finishedBlock];
		
		if(loadingHead)
			return;
		
		loadingHead = YES;
		
		if(listRecords.count==0) //如果是首次加载，转为调用more
		{
			isReload = YES; //如果是首次加载，则认为是reload
			[self moreWithFinishedBlock:nil];
			return;
		}
		queryCount = _segmentLength;
	}
	
	// 异步发送loadHead请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryAfterRecord:nil count:queryCount callback:^(NSArray *records, BOOL reachEnd, NSError *error) {
			__typeof(self) sself = wself;
			[sself preposeRecords:records reachEnd:reachEnd error:error];
		}];
	});
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	id tailRecord;
	NSInteger queryCount;
	@synchronized(self)
	{
		if(finishedBlock)
			[tailFinishedBlocks addObject:finishedBlock];
		
		if(loadingTail)
			return;
		
		loadingTail = YES;
		
		tailRecord = [listRecords lastObject];
		queryCount = _segmentLength;
	}
	
	// 异步发送loadTail请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryAfterRecord:tailRecord count:queryCount callback:^(NSArray *records, BOOL reachEnd, NSError *error) {
			__typeof(self) sself = wself;
			[sself appendRecords:records reachEnd:reachEnd error:error queryTailRecord:tailRecord];
		}];
	});
}

- (void)deleteRecords:(NSArray*)records
{
	if(records.count==0)
		return;
	NSMutableSet* deleted = [NSMutableSet new];
	@synchronized(self)
	{
		for (id record in records) {
			for (NSInteger i=0;i<listRecords.count;i++) {
				id r = listRecords[i];
				if([self doesRecord:r hasSameIDWithRecord:record])
				{
					[deleted addObject:@(i)];
					break;
				}
			}
		}
		if(deleted.count)
		{
			NSArray* sorted = [[deleted allObjects] sortedArrayUsingSelector:@selector(compare:)];
			for (NSInteger i = sorted.count-1;i>=0;i--) {
				NSNumber* indexNum = sorted[i];
				[listRecords removeObjectAtIndex:indexNum.integerValue];
			}
			inmutablelist = nil;
			self.needsSave = YES;
			if([NSThread currentThread]==[NSThread mainThread])
				[self notifyObserversOnMainThreadWithModified:nil deleted:sorted added:nil];
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self notifyObserversOnMainThreadWithModified:nil deleted:sorted added:nil];
				});
			}
		}
	}
}

- (void)replaceRecords:(NSArray*)records
{
	if(records.count==0)
		return;
	NSMutableSet* modified = [NSMutableSet new];
	@synchronized(self)
	{
		for (id record in records) {
			for (NSInteger i=0;i<listRecords.count;i++) {
				id r = listRecords[i];
				if([self doesRecord:r hasSameIDWithRecord:record])
				{
					[modified addObject:@(i)];
					[listRecords replaceObjectAtIndex:i withObject:record];
					break;
				}
			}
		}
		if(modified.count)
		{
			inmutablelist = nil;
			self.needsSave = YES;
			NSArray* sorted = [[modified allObjects] sortedArrayUsingSelector:@selector(compare:)];
			if([NSThread currentThread]==[NSThread mainThread])
				[self notifyObserversOnMainThreadWithModified:sorted deleted:nil added:nil];
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self notifyObserversOnMainThreadWithModified:sorted deleted:nil added:nil];
				});
			}
		}
	}
}

- (void)preposeRecords:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error
{
	// 保证preposeRecordsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self preposeRecordsOnMainThread:records reachEnd:reachEnd error:error];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself preposeRecordsOnMainThread:records reachEnd:reachEnd error:error];
		});
	}
}

// 在主线程进行列表修改，同时发送列表修改通知和finishedBlock调用。这三步必须连接调用，不可打断。因为加载列表头和加载列表尾可同时进行，如果这三步可拆分，可能会出现调用顺序混乱，导致列表修改通知不正确。
- (void)preposeRecordsOnMainThread:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error
{
	NSMutableArray* deletedIndics = [NSMutableArray new];
	NSMutableDictionary* dicAdded = [NSMutableDictionary new];
	NSMutableDictionary* dicReplaced = [NSMutableDictionary dictionary];
	NSArray* deleted = nil;
	NSArray* added = nil;
	NSArray* modified = nil;
	
	NSArray* finishedBlocks;
	
	NSInteger count = records.count;//查询到的记录的条数

	@synchronized(self)
	{
		if(error==nil)
		{
			if(isReload)
			{
				for(NSInteger i = 0; i<listRecords.count; i++)
				{
					[deletedIndics addObject:@(i)];
				}
				inmutablelist = nil;
				self.needsSave = YES;
				
				_reachEnd = reachEnd;
				
				for (NSInteger i = 0; i<records.count; i++)
				{
					dicAdded[@(i)] = records[i];
				}
			}
			else
			{
				NSInteger localCount = listRecords.count;
				if(count==0 && localCount==0)
				{
					_reachEnd = YES;
				}
				else if(count==0)//数据全部删除了
				{
					for (NSInteger i = 0; i<localCount; i++) {
						[deletedIndics addObject:@(i)];
					}
					_reachEnd = YES;
				}
				else if(localCount==0)//本地没有任何记录
				{
					for (NSInteger i = 0; i<count; i++) {
						dicAdded[@(i)] = records[i];
					}
				}
				else
				{
					id newlastRecord = [records lastObject];
					id localFirstRecord = listRecords[0];
					NSComparisonResult compareResult = [self compareRecord:newlastRecord withRecord:localFirstRecord];
					if(compareResult!=NSOrderedAscending)//新获取的最后一条记录大于等于本地的第一条记录，也就是说新取到的数据有部分是重复的，此时执行比对操作，检测出添加、删除、修改过的条目
					{
						NSInteger iNew=0,iOld=0;
						for (;iNew<count && iOld<localCount; ) {
							id recordnew = records[iNew];
							id recordold = listRecords[iOld];
							NSComparisonResult compareResult = [self compareRecord:recordnew withRecord:recordold];
							if(compareResult==NSOrderedAscending)//小于
							{
								dicAdded[@(iNew)] = recordnew;
								iNew++;
							}
							else if(compareResult == NSOrderedDescending)//大于
							{
								[deletedIndics addObject:@(iOld)];
								iOld++;
							}
							else //等于
							{
								dicReplaced[@(iOld)] = recordnew;
								iNew++,iOld++;
							}
						}
						for (; iNew<count; iNew++) {
							dicAdded[@(iNew)] = records[iNew];
						}
						if(reachEnd)//count<=queryCount)	//查询结果全部取完，后面没有了。
						{
							for (; iOld<localCount; iOld++) {
								[deletedIndics addObject:@(iOld)];
							}
						}
					}
					else// 新获取的记录全部是新增的，可能是因为很久没有刷新导致的。由于不知道还有没有更多新增的记录，这种情况下就抛弃之前的所有记录，只留下最新加载的。
					{
						for (NSInteger i = 0; i<localCount; i++) {
							[deletedIndics addObject:@(i)];
						}
						for (NSInteger i = 0; i<count; i++) {
							dicAdded[@(i)] = records[i];
						}
					}
				} // end 新旧比对
			}//end if(reload==NO)
			
			NSInteger replacedCount = dicReplaced.count;
			if(replacedCount)
			{
				modified = [dicReplaced.allKeys  sortedArrayUsingSelector:@selector(compare:)];
				for (NSInteger i=0; i<replacedCount; i++) {
					NSNumber* index = modified[i];
					[listRecords replaceObjectAtIndex:[index integerValue] withObject:dicReplaced[index]];
				}
			}
			NSInteger deletedCount = deletedIndics.count;
			if(deletedCount)
			{
				deleted = [deletedIndics sortedArrayUsingSelector:@selector(compare:)];
				for (NSInteger i = deletedCount-1; i>=0; i--) {
					[listRecords removeObjectAtIndex:[deleted[i] integerValue]];
				}
			}
			NSInteger addedCount = dicAdded.count;
			if(addedCount)
			{
				added = [dicAdded.allKeys sortedArrayUsingSelector:@selector(compare:)];
				for (NSInteger i=0; i<addedCount; i++) {
					NSNumber* index = added[i];
					[listRecords insertObject:dicAdded[index] atIndex:[index integerValue]];
				}
			}
			
			NSInteger changedCount = deletedCount+addedCount+replacedCount;
			if(changedCount)
			{
				inmutablelist = nil;
				self.needsSave = YES;
			}
			_reachEnd = reachEnd; //refresh时重置_reachEnd
		} // end if(error==nil)
		
		loadingHead = NO;
		isReload = NO;
		finishedBlocks = [headFinishedBlocks copy];
		[headFinishedBlocks removeAllObjects];
	}// end @synchronized(self)
	
	if(added.count || deleted.count || modified.count)
		[self notifyObserversOnMainThreadWithModified:modified deleted:deleted added:added];
	
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
		if(queryTailRecord == [listRecords lastObject] //如果queryTailRecord与当前tailRecord一样，说明列表没有过reload。否则本次queryTail就要被取消。
		   && error==nil)
		{
			if(records.count)
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
			_reachEnd = reachEnd;
		}
		
		
		if(queryTailRecord==nil && loadingHead)//首次加载，是由refresh或reload方法发起的
		{
			loadingHead = NO;
			headFinished = [headFinishedBlocks copy];
			[headFinishedBlocks removeAllObjects];
		}
		
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

- (void)addSegListObserver:(id<IDNSegListObserver>)observer
{
	if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
		return;
	if([observer respondsToSelector:@selector(segList:modifiedIndics:deletedIndics:addedIndics:)]==NO)//观察者没有实现指定方法
		return;
	[observers addPointer:(__bridge void *)(observer)];
}
- (void)delSegListObserver:(id<IDNSegListObserver>)observer
{
	[observers removePointerIdentically:(__bridge void *)(observer)];
}

- (void)notifyObserversOnMainThreadWithModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added
{
	BOOL needsCompact = NO;
	for (id<IDNSegListObserver> observer in observers) {
		if(observer==nil)
		{
			needsCompact = YES;
			continue;
		}
		[observer segList:self modifiedIndics:modified deletedIndics:deleted addedIndics:added];
	}
	[observers compact];
}

#pragma mark 需要重载的方法

// callback必须要被调用，否则会永远处于loadingTail状态。tailRecord==nil表示首次调用，应该获取列表第一段。
- (void)queryAfterRecord:(id)tailRecord count:(NSInteger)count callback:(void (^)(NSArray* records, BOOL reachEnd, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

- (NSComparisonResult)compareRecord:(id)aRecord withRecord:(id)anotherRecord
{
	@throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"不要使用父类的%s方法，子类应该完全覆盖它！",__FUNCTION__] userInfo:nil];
	return NSOrderedSame;
}

- (BOOL)doesRecord:(id)record hasSameIDWithRecord:(id)anotherRecord
{
	@throw @"子类应该重载此方法";
	return NO;
}
@end
