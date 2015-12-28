//
//  IDNPageList.m
//

#import "IDNPageList.h"
#import "NSPointerArray+IDNExtend.h"

#define DefaultPageSize 20

@interface IDNPageList()
@property(nonatomic) BOOL needsSave;
@property(nonatomic) BOOL loading; // 是否正在加载
@end

@implementation IDNPageList
{
	NSArray* inmutablelist; //固定列表。是对listRecords的拷贝。主要是考虑多线程的问题，在读取列表内容的同时，后台可能会修改列表。每当列表被修改时，inmutablelist会设为nil，然后当访问list属性时，会重新生成inmutablelist
	NSMutableArray* listRecords;
	
	BOOL isReload; //在loading时，区分是reload还是more。
	NSMutableArray* finishedBlocks;

	NSPointerArray* observers;
	
	NSMutableDictionary* persistDict;
}

- (instancetype)initWithPersistFilePath:(NSString *)persistFilePath
{
	self = [super init];
	if (self) {
		_pageSize = DefaultPageSize;
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
		
		finishedBlocks = [NSMutableArray new];
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
	[self moreWithFinishedBlock:finishedBlock reload:YES];
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock
{
	[self moreWithFinishedBlock:finishedBlock reload:NO];
}

- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock reload:(BOOL)reload
{
	NSInteger pageSize;
	NSInteger page;
	@synchronized(self)
	{
		if(_loading)
			return;
		if(reload==NO && _reachEnd) //已经取完了
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				if(finishedBlock)
					finishedBlock(nil);
			});
			return;
		}
		
		_loading = YES;
		isReload = reload;
		
		pageSize = _pageSize;
		if(isReload)
			page = 0;
		else
			page = _pagesCount;
		
		if(finishedBlock)
			[finishedBlocks addObject:finishedBlock];
	}
	
	// 异步发送loadTail请求
	__weak __typeof(self) wself = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self queryWithPageIndex:page pageSize:pageSize callback:^(NSArray *records, BOOL reachEnd, NSError *error) {
			__typeof(self) sself = wself;
			[sself appendRecords:records reachEnd:reachEnd error:error];
		}];
	});
}

- (void)appendRecords:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error
{
	// 保证preposeRecordsOnMainThread:总是在主线程完成
	if([NSThread currentThread] == [NSThread mainThread])
		[self appendRecordsOnMainThread:records reachEnd:reachEnd error:error];
	else
	{
		__weak __typeof(self) wself = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			__typeof(self) sself = wself;
			[sself appendRecordsOnMainThread:records reachEnd:reachEnd error:error];
		});
	}
}

// queryTailRecord用于检测这次Query是否被取消。
- (void)appendRecordsOnMainThread:(NSArray*)records reachEnd:(BOOL)reachEnd error:(NSError*)error
{
	NSMutableArray* added = nil;
	NSMutableArray* deleted = nil;
	NSArray* finished = nil;
	@synchronized(self)
	{
		if(error==nil)
		{
			if(isReload && listRecords.count)
			{
				deleted = [NSMutableArray new];
				for (NSInteger i=listRecords.count-1; i>=0; i--) {
					[deleted addObject:@(i)];
				}
				[listRecords removeAllObjects];
			}
			
			if(records.count)
			{
				added = [NSMutableArray new];
				
				NSInteger prevCount = listRecords.count;
				for (NSInteger i = 0; i<records.count; i++)
				{
					[added addObject:@(i+prevCount)];
				}
				
				[listRecords addObjectsFromArray:records];
			}
			
			if(added.count || deleted.count)
			{
				inmutablelist = nil;
				self.needsSave = YES;
			}
			_reachEnd = reachEnd;
			if(isReload)
				_pagesCount = 1;
			else
			{
				if(records.count>0)
					_pagesCount++;
			}
		}
		
		_loading = NO;
		finished = [finishedBlocks copy];
		[finishedBlocks removeAllObjects];
	}
	
	if(added.count || deleted.count)
		[self notifyObserversOnMainThreadWithModified:nil deleted:deleted added:added];
	
	if(finished.count)
		[self notifyFinishedBlocksOnMainThread:finished error:error];
}

- (void)deleteRecordAtIndex:(NSInteger)index
{
	@synchronized(self)
	{
		if(index<0 || index>=listRecords.count)
			return;
		
		[listRecords removeObjectAtIndex:index];
		inmutablelist = nil;
		self.needsSave = YES;
	}
	if([NSThread currentThread]==[NSThread mainThread])
		[self notifyObserversOnMainThreadWithModified:nil deleted:@[@(index)] added:nil];
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self notifyObserversOnMainThreadWithModified:nil deleted:@[@(index)] added:nil];
		});
	}
}

- (void)replaceRecord:(id)record atIndex:(NSInteger)index
{
	if(record==nil)
		return;
	
	@synchronized(self)
	{
		if(index<0 || index>=listRecords.count)
			return;
		
		[listRecords replaceObjectAtIndex:index withObject:record];
		inmutablelist = nil;
		self.needsSave = YES;
	}
	if([NSThread currentThread]==[NSThread mainThread])
		[self notifyObserversOnMainThreadWithModified:@[@(index)] deleted:nil added:nil];
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self notifyObserversOnMainThreadWithModified:@[@(index)] deleted:nil added:nil];
		});
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

- (void)notifyFinishedBlocksOnMainThread:(NSArray*)finishBlocks error:(NSError*)error
{
	for (void (^finishedBlock)(NSError*error) in finishBlocks) {
		finishedBlock(error);
	}
}

- (void)addPageListObserver:(id<IDNPageListObserver>)observer
{
	if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
		return;
	if([observer respondsToSelector:@selector(pageList:modifiedIndics:deletedIndics:addedIndics:)]==NO)//观察者没有实现指定方法
		return;
	[observers addPointer:(__bridge void *)(observer)];
}
- (void)delPageListObserver:(id<IDNPageListObserver>)observer
{
	[observers removePointerIdentically:(__bridge void *)(observer)];
}

- (void)notifyObserversOnMainThreadWithModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added
{
	BOOL needsCompact = NO;
	for (id<IDNPageListObserver> observer in observers) {
		if(observer==nil)
		{
			needsCompact = YES;
			continue;
		}
		[observer pageList:self modifiedIndics:modified deletedIndics:deleted addedIndics:added];
	}
	[observers compact];
}

#pragma mark 需要重载的方法

// callback必须要被调用，否则会永远处于loading状态
- (void)queryWithPageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize callback:(void (^)(NSArray* records, BOOL reachEnd, NSError* error))callback
{
	@throw @"子类应该重载此方法";
}

@end
