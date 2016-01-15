//
//  IDNTaskQueue.m
//  IDNFramework
//
//  Created by photondragon on 15/10/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "IDNTaskQueue.h"

@implementation IDNTaskQueue
{
	NSMutableArray* queue;
	BOOL isPerforming;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		queue = [NSMutableArray new];
	}
	return self;
}

- (void)performInSequenceQueue:(void (^)())taskBlock
{
	if(taskBlock==nil)
		return;
	@synchronized(self)
	{
		if(isPerforming)
		{
			[queue addObject:taskBlock];
		}
		else
		{
			isPerforming = YES;
			__weak __typeof(self) wself = self;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				__typeof(self) sself = wself;
				[sself performTask:taskBlock];
			});
		}
	}
}

- (void)performTask:(void (^)())taskBlock
{
	taskBlock();
	
	while (1) {
		@synchronized(self) {
			taskBlock = [queue firstObject];
			if(taskBlock==nil)
			{
				isPerforming = NO;
				return;
			}
			[queue removeObjectAtIndex:0];
		}
		taskBlock();
	}
}
@end
