//
//  SegmentQuery.m
//  miku
//
//  Created by fred on 14/11/27.
//  Copyright (c) 2014年 ywiosdev. All rights reserved.
//

#import "SegmentQuery.h"

@interface SegmentQuery()
{
//	NSInteger grossCount;	//查询结果总条数。每获取一段，这个值都可能改变。总是等于服务器上最新一次的查询结果的总条数。
	NSMutableArray* arrayResult;	//已获取的搜索结果。即使获取了所有的搜索结果，这个数组的元素个数也不一定等于grossCount，可能大也可能小。因为这个数组里的记录是分段获取的，每段的获取时间不一样，有新有旧，所以与服务器上的可能不一致。
	//当前段是指最近一次查询取得的数据保存在arrayResult中的范围
	BOOL isOperating; //是否在执行查询操作。
}
@end

@implementation SegmentQuery

- (NSArray*)list
{
	@synchronized(self)
	{
		return arrayResult;
	}
}

- (instancetype)init
{
	if([self isMemberOfClass:[SegmentQuery class]])
		@throw [NSException exceptionWithName:NSGenericException reason:@"不要实例化SegmentQuery类，应使用其派生类。" userInfo:nil];

	self = [super init];
	if (self) {
		arrayResult = [[NSMutableArray alloc] init];
		_segmentLength = 20;
	}
	return self;
}

// 查询下一段记录。返回查询到的记录条数，查询失败返回-1
- (NSError*)more
{
	return [self queryNextSegment];
}

- (NSError*)queryNextSegment
{
	NSInteger segmentLength;
	id localLastRecord;//本地最后一条记录
	@synchronized(self)
	{
		if(_reachEnd)//已经取得了所有数据
			return nil;
		if(isOperating)
			return [NSError errorWithDomain:@"SegmentQuery" code:0 userInfo:@{NSLocalizedDescriptionKey:@"上一次查询正在进行中，请稍后再试"}];
		isOperating = TRUE;
		segmentLength = _segmentLength;
		NSInteger curRecordsCount = arrayResult.count;//已获取的记录条数
		if(curRecordsCount==0)
			localLastRecord = nil;
		else
			localLastRecord = arrayResult[curRecordsCount-1];
	}
	
	NSError* error;
	NSArray* records = [self queryAfterRecord:localLastRecord count:segmentLength+1 error:&error];//查询本地最后一条记录之后的segmentLength+1条记录

	NSInteger count = records.count;//查询到的记录的条数
	NSInteger originCount;
	@synchronized(self)
	{
		originCount = arrayResult.count;
		isOperating = FALSE;
		if(records==nil)//查询失败
		{
			if(error==nil)
				error = [NSError errorWithDomain:@"SegmentQuery" code:0 userInfo:@{NSLocalizedDescriptionKey:@"未知错误\nSegmentQuery子类没有设置错误信息"}];
			return error;
		}
		if(count>segmentLength)//获取到了segmentLength+1条记录，表示后面还有记录没取完
		{
			count--; //保存segmentLength条记录，最后一条不保存
		}
		else//查询结果全部取完，后面没有了。
		{
			_reachEnd = TRUE;
		}
		for (NSInteger i = 0;i<count;i++) {
			[arrayResult addObject:records[i]];
		}
	}
//	sleep(2);
	NSMutableDictionary* added = [NSMutableDictionary dictionary];
	for (NSInteger i = 0; i<count; i++) {
		added[@(originCount+i)] = records[i];
	}
	if(count>0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self.listChangedBlock)
				self.listChangedBlock(nil, added, nil);
		});
	}
	return nil;
}

- (NSError*)refresh
{
	NSInteger segmentLength;
	@synchronized(self)
	{
		if(isOperating)
			return nil;
		isOperating = YES;
		segmentLength = _segmentLength;
	}
	
	NSError* error;
	NSArray* records = [self queryAfterRecord:nil count:segmentLength+1 error:&error];//查询前segmentLength+1条记录
	if(records==nil)//查询失败
	{
		@synchronized(self){ isOperating = NO; }
		if(error==nil)
			error = [NSError errorWithDomain:@"SegmentQuery" code:0 userInfo:@{NSLocalizedDescriptionKey:@"未知错误\nSegmentQuery子类没有设置错误信息"}];
		return error;
	}
	NSMutableDictionary* added = [NSMutableDictionary dictionary];
	NSMutableDictionary* deleted = [NSMutableDictionary dictionary];
	NSMutableDictionary* modified = [NSMutableDictionary dictionary];
	NSInteger count = records.count;//查询到的记录的条数
	
	NSInteger localCount = arrayResult.count;//此时可以读，因为这个时候isOperating==YES，其它线程不可能修改数据。

	NSInteger refreshedCount;
	@synchronized(self){
		if(count==0 && localCount==0)
		{
			isOperating = NO;
			_reachEnd = YES;
			return nil;
		}
		
		if(count==0)//数据全部删除了
		{
			for (NSInteger i = 0; i<localCount; i++) {
				deleted[@(i)] = arrayResult[i];
			}
		}
		else if(localCount==0)//本地没有任何记录
		{
			for (NSInteger i = 0; i<count; i++) {
				added[@(i)] = records[i];
			}
		}
		else
		{
			id newlastRecord = [records lastObject];
			id localFirstRecord = arrayResult[0];
			NSComparisonResult compareResult = [self compareRecord:newlastRecord withRecord:localFirstRecord];
			if(compareResult!=NSOrderedAscending)//新获取的最后一条记录大于等于本地的第一条记录，也就是说新取到的数据有部分是重复的，此时执行比对操作，检测出添加、删除、修改过的条目
			{
				NSInteger iNew=0,iOld=0;
				for (;iNew<count && iOld<localCount; ) {
					id recordnew = records[iNew];
					id recordold = arrayResult[iOld];
					NSComparisonResult compareResult = [self compareRecord:recordnew withRecord:recordold];
					if(compareResult==NSOrderedAscending)//小于
					{
						added[@(iNew)] = recordnew;
						iNew++;
					}
					else if(compareResult == NSOrderedDescending)//大于
					{
						deleted[@(iOld)] = recordold;
						iOld++;
					}
					else //等于
					{
						if([self isRecordModifiedWithOldInfo:recordold newInfo:recordnew])//检测是否是修改过的record
						{
							modified[@(iNew)] = recordnew;
						}
						iNew++,iOld++;
					}
				}
				for (; iNew<count; iNew++) {
					added[@(iNew)] = records[iNew];
				}
				if(count<=segmentLength)	//查询结果全部取完，后面没有了。
				{
					for (; iOld<localCount; iOld++) {
						deleted[@(iOld)] = records[iOld];
					}
				}
			}
			else// 新获取的记录全部是新增的，可能是因为很久没有刷新导致的。由于不知道还有没有更多新增的记录，这种情况下就抛弃之前的所有记录，只留下最新加载的。
			{
				for (NSInteger i = 0; i<localCount; i++) {
					deleted[@(i)] = arrayResult[i];
				}
				for (NSInteger i = 0; i<count; i++) {
					added[@(i)] = records[i];
				}
			}
		}
	
		if(count<=segmentLength)
			_reachEnd = TRUE;
		
		NSInteger deletedCount = deleted.count;
		NSArray* deletedIndics = [deleted.allKeys sortedArrayUsingSelector:@selector(compare:)];
		for (NSInteger i = deletedCount-1; i>=0; i--) {
			[arrayResult removeObjectAtIndex:[deletedIndics[i] integerValue]];
		}
		NSInteger addedCount = added.count;
		NSArray* addedIndics = [added.allKeys sortedArrayUsingSelector:@selector(compare:)];
		for (NSInteger i=0; i<addedCount; i++) {
			NSNumber* index = addedIndics[i];
			[arrayResult insertObject:added[index] atIndex:[index integerValue]];
		}
		NSInteger modifiedCount = modified.count;
		NSArray* modifiedIndics = modified.allKeys;
		for (NSInteger i=0; i<modifiedCount; i++) {
			NSNumber* index = modifiedIndics[i];
			[arrayResult replaceObjectAtIndex:[index integerValue] withObject:modified[index]];
		}
		
		refreshedCount = deletedCount+addedCount+modifiedCount;
		isOperating = NO;
	}//end @synchronized(self)
//	if(refreshedCount>0)//没有任何更新也发出通知，相当于是操作结束通知。
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self.listChangedBlock)
				self.listChangedBlock(deleted, added, modified);
		});
	}
	return nil;
}

- (NSError*)reload
{
	NSInteger segmentLength;
	@synchronized(self)
	{
		if(isOperating)
			return nil;
		isOperating = TRUE;
		segmentLength = _segmentLength;
	}
	NSError* error;
	NSArray* records = [self queryAfterRecord:nil count:segmentLength+1 error:&error];//查询前segmentLength+1条记录
	
	NSMutableDictionary* added = [NSMutableDictionary dictionary];
	NSMutableDictionary* deleted = [NSMutableDictionary dictionary];
	
	NSInteger count;
	NSInteger localCount;
	@synchronized(self)
	{
		if(records==nil)
		{
			isOperating = NO;
			if(error==nil)
				error = [NSError errorWithDomain:@"SegmentQuery" code:0 userInfo:@{NSLocalizedDescriptionKey:@"未知错误\nSegmentQuery子类没有设置错误信息"}];
			return error;
		}
		
		count = records.count;
		if(count<=segmentLength)
			_reachEnd = YES;
		else
			count--;

		localCount = arrayResult.count;
		for (NSInteger i = 0; i<localCount; i++) {
			deleted[@(i)] = arrayResult[i];
		}
		for (NSInteger i = 0; i<count; i++) {
			added[@(i)] = records[i];
		}
		
		[arrayResult removeAllObjects];
		for (NSInteger i = 0; i<count; i++) {
			arrayResult[i] = records[i];
		}
		isOperating = NO;
	}
	if(count>0 || localCount>0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self.listChangedBlock)
				self.listChangedBlock(deleted, added, nil);
		});
	}
	
	return nil;
}

- (NSArray*)queryAfterRecord:(id)record count:(NSInteger)count error:(NSError**)error
{
	@throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"不要使用父类的%s方法，子类应该完全覆盖它！",__FUNCTION__] userInfo:nil];
	return @[];
}

- (NSComparisonResult)compareRecord:(id)aRecord withRecord:(id)anotherRecord
{
	@throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"不要使用父类的%s方法，子类应该完全覆盖它！",__FUNCTION__] userInfo:nil];
	return NSOrderedSame;
}

- (BOOL)isRecordModifiedWithOldInfo:(id)oldInfo newInfo:(id)newInfo
{
	@throw [NSException exceptionWithName:NSGenericException reason:[NSString stringWithFormat:@"不要使用父类的%s方法，子类应该完全覆盖它！",__FUNCTION__] userInfo:nil];
	return TRUE;
}

- (void)recordChanged:(id)changedRecord
{
	NSInteger i=0;
	for (;i<self.list.count;i++) {
		id record = self.list[i];
		NSComparisonResult result = [self compareRecord:changedRecord withRecord:record];
		if(result==NSOrderedDescending)
			continue;
		else if(result==NSOrderedSame)//同一条记录
		{
			if([self isRecordModifiedWithOldInfo:record newInfo:changedRecord])//记录被修改了
			{
				@synchronized(self)
				{
					[arrayResult replaceObjectAtIndex:i withObject:changedRecord];
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					if(self.listChangedBlock)
						self.listChangedBlock(nil, nil, @{@(i):changedRecord});
				});
			}
			return;
		}
		else//新增的
			break;
	}
	
	if(i>0 && i>=self.list.count)//排除self.list.count==0的情况
		return;
	//注意列表为空时changedRecord也算新增条目
	@synchronized(self)
	{
		[arrayResult insertObject:changedRecord atIndex:i];
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		if(self.listChangedBlock)
			self.listChangedBlock(nil, @{@(i):changedRecord}, nil);
	});
}

- (void)recordDeleted:(id)deletedRecord
{
	NSInteger i=0;
	for (;i<self.list.count;i++) {
		id record = self.list[i];
		NSComparisonResult result = [self compareRecord:deletedRecord withRecord:record];
		if(result==NSOrderedSame)//同一条记录
		{
			@synchronized(self)
			{
				[arrayResult removeObjectAtIndex:i];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				if(self.listChangedBlock)
					self.listChangedBlock(@{@(i):deletedRecord}, nil, nil);
			});
			return;
		}
	}
}

@end
