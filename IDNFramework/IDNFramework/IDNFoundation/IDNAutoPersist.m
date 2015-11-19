//
//  IDNAutoPersist.m
//  IDNFramework
//
//  Created by photondragon on 15/8/5.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNAutoPersist.h"
#import <objc/runtime.h>

#define MinSaveTimeInterval 2.0 //最小保存时间间隔

@implementation IDNAutoPersist
{
	NSMutableDictionary* dic;
	NSString* persistPath;
	BOOL isSaving;
	NSTimeInterval lastSaveTime;
}

+ (instancetype)defaultPersister
{
	static IDNAutoPersist* defaultPersister = nil;
	if(defaultPersister==nil)
	{
		NSString* path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"IDNAutoPersistDefault.dat"];
		defaultPersister = [[IDNAutoPersist alloc] initWithPersistPath:path];
	}
	return defaultPersister;
}

- (instancetype)init
{
	return [self initWithPersistPath:nil];
}
- (instancetype)initWithPersistPath:(NSString*)path
{
	self = [super init];
	if (self) {
		if(path.length)
		{
			persistPath = path;
			dic = [NSMutableDictionary dictionaryWithContentsOfFile:path];
			if(dic==nil)
				dic = [NSMutableDictionary new];
		}
	}
	return self;
}

- (void)setNeedSaving
{
	@synchronized(self)
	{
		if(isSaving)
			return;
		else
		{
			isSaving = YES;
			NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
			NSTimeInterval deltaTime = now - lastSaveTime;
			NSTimeInterval delay;
			if( deltaTime >= MinSaveTimeInterval )
				delay = 0;
			else
				delay = MinSaveTimeInterval - deltaTime;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[self save];
			});
		}
	}
}
- (void)save
{
	NSMutableDictionary* save;
	@synchronized(self)
	{
		isSaving = NO;
		if(persistPath==nil)
			return;
		save = [dic mutableCopy];
	}
	[save writeToFile:persistPath atomically:YES];
}

#pragma mark 修改

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
	@synchronized(self)
	{
		[dic setObject:anObject forKeyedSubscript:aKey];
		[self setNeedSaving];
	}
}

- (void)removeObjectForKey:(id)aKey
{
	@synchronized(self)
	{
		[dic removeObjectForKey:aKey];
		[self setNeedSaving];
	}
}

- (void)removeObjectsForKeys:(NSArray *)keyArray
{
	@synchronized(self)
	{
		[dic removeObjectsForKeys:keyArray];
		[self setNeedSaving];
	}
}

- (void)setDictionary:(NSDictionary *)otherDictionary
{
	@synchronized(self)
	{
		[dic setDictionary:otherDictionary];
		[self setNeedSaving];
	}
}

- (void)removeAllObjects
{
	@synchronized(self)
	{
		[dic removeAllObjects];
		[self setNeedSaving];
	}
}

#pragma mark 读取

- (NSUInteger)count
{
	@synchronized(self)
	{
		return [dic count];
	}
}
- (id)objectForKey:(id)aKey
{
	@synchronized(self)
	{
		return [dic objectForKey:aKey];
	}
}

- (NSArray*)allKeys
{
	@synchronized(self)
	{
		return [dic allKeys];
	}
}

- (NSArray *)allKeysForObject:(id)anObject
{
	@synchronized(self)
	{
		return [dic allKeysForObject:anObject];
	}
}
- (NSArray*)allValues
{
	@synchronized(self)
	{
		return [dic allValues];
	}
}

@end
