/** @file IDNAsyncTask.m
 内部使用NSOperationQueue来实现多线程操作
 */

#import "IDNAsyncTask.h"

#define HotTaskRatio 5 //每执行HotTaskRatio个任务中，只有一个是普通任务，其余都是高优先级任务
enum AsyncTaskState
{
	AsyncTaskStateWaiting=0,
	AsyncTaskStateRun, //正在执行或执行完成
};

@interface AsyncTaskTask:NSObject

@property(nonatomic,strong) id key;
@property(nonatomic,strong) id group;
@property(nonatomic,strong) id object;
@property(atomic) enum AsyncTaskState state; //任务的当前状态
@property(atomic) BOOL isCancelled;//任务是否已取消
@property(nonatomic,strong) IDNAsyncTaskBlock taskBlock;
@property(nonatomic,strong) IDNAsyncTaskFinishedBlock finishedBlock;
@property(nonatomic,strong) IDNAsyncTaskCancelledBlock cancelledBlock;

@end

@implementation AsyncTaskTask

@end

@interface AsyncTaskGroup : NSObject
@property(nonatomic,strong) id group; //组名
@property(nonatomic,strong) NSMutableDictionary* dicTasks;//组内任务
@end
@implementation AsyncTaskGroup

- (instancetype)init
{
	self = [super init];
	if (self) {
		_dicTasks = [[NSMutableDictionary alloc] init];
	}
	return self;
}

@end

@interface IDNAsyncTask()
{
	NSMutableArray* arrayAllTasks; //包含所有任务。不包括已取消的任务
	NSMutableArray* arrayHotTasks; //高优先级任务
	NSMutableDictionary* dicGroups; //任务组
	NSMutableArray* arrayCancelledTasks; //已取消的任务。
	id currentGroup; //当前组，组内任务优先级高
	NSInteger concurrentTasksCount; //当前正在运行的任务数
	BOOL isScheduleATaskSubmitted; //scheduleATask方法是否提交了
	BOOL isReportCancelledTasksSubmitted; //reportCancelledTasksOnMainThread方法是否已提交
//	NSThread* scheduleThread;
}
@property(nonatomic) NSInteger maxConcurrentTasks; //最大并发任务数
@property(nonatomic,strong) NSMutableDictionary* dicThreadTasks; //线程对应的任务
-(void) cancelTaskWithKey:(id)taskKey group:(id)group;
-(void) cancelAllTasksInGroup:(id)group;
@end

@implementation IDNAsyncTask

+(IDNAsyncTask*)taskManager
{
	static IDNAsyncTask* taskManager = nil;
	if(taskManager==nil)
	{
		@synchronized(self)
		{
			if(taskManager==nil)
			{
				taskManager = [[IDNAsyncTask alloc] initPrivate];
			}
		}
	}
	return taskManager;
}

-(instancetype) init
{
	return nil;
}

-(instancetype) initPrivate
{
	if((self = [super init]))
	{
		arrayAllTasks = [[NSMutableArray alloc] init];
		arrayHotTasks = [[NSMutableArray alloc] init];
		arrayCancelledTasks = [[NSMutableArray alloc] init];
		dicGroups = [[NSMutableDictionary alloc] init];
		_dicThreadTasks = [[NSMutableDictionary alloc] init];
		_maxConcurrentTasks = 2;
//		scheduleThread = [[NSThread alloc] initWithTarget:self selector:@selector(scheduleThread) object:nil];
//		[scheduleThread start];
	}
	return self;
}

#pragma mark Task
+(NSOperationQueue*) operationQueue
{
	static NSOperationQueue* xLoaderTaskQueue = nil;

	if(xLoaderTaskQueue==nil)
	{
		@synchronized(self)
		{
			if(xLoaderTaskQueue==nil)
			{
				xLoaderTaskQueue = [[NSOperationQueue alloc] init];
				xLoaderTaskQueue.maxConcurrentOperationCount = [IDNAsyncTask taskManager].maxConcurrentTasks;
			}
		}
	}
	return xLoaderTaskQueue;
}

- (int)scheduleATask
{
	static int n=0;
	int count = 0;
	@synchronized(self)
	{
		while(concurrentTasksCount<_maxConcurrentTasks)//并发数未达上限
		{
			NSInteger tasksCount = arrayAllTasks.count;
			if(concurrentTasksCount>=tasksCount) //没有任务了
				break;
			n++;
			NSInteger hotTasksCount = arrayHotTasks.count;
			BOOL isHot;
			if(hotTasksCount==0) //没有Hot任务
				isHot = NO;
			else if(hotTasksCount<tasksCount) //有Hot任务和普通任务
			{
				if(n%HotTaskRatio)
					isHot = YES;
				else
					isHot = NO;
			}
			else //if(hotTasksCount>=tasksCount) //没有普通任务
				isHot = YES;
			
			AsyncTaskTask* aTask = nil;
			
			if (isHot) //Hot任务
			{
				for (AsyncTaskTask* task in arrayHotTasks) {
					if (task.state==AsyncTaskStateWaiting) {
						aTask = task;
						break;
					}
				}
				if(aTask==nil)//没有Hot任务了
					isHot = NO;
			}
			if(isHot==NO) //普通任务
			{
				for (AsyncTaskTask* task in arrayAllTasks) {
					if (task.group!=currentGroup && task.state==AsyncTaskStateWaiting) {
						aTask = task;
						break;
					}
				}
			}

			aTask.state = AsyncTaskStateRun; //必须在加锁区内设置这个属性，否则可能导致另一个scheduleATask线程也获取到这个任务
			concurrentTasksCount++;
			NSInvocationOperation* op	= [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runATask:) object:aTask];
			[[IDNAsyncTask operationQueue] addOperation:op];
			count++;
		}
		
		if (concurrentTasksCount<arrayAllTasks.count) {//死循环风险？？？
			dispatch_async(dispatch_get_main_queue(), ^{
				[self scheduleATask];
			});
		}
		else
			isScheduleATaskSubmitted = NO;
	}
	return count;
}

//-(void) scheduleThread
//{
//	while (1) {
//		int count = [self scheduleATask];
//		if(count==0)
//			usleep(5000);
//	}
//}

//此函数由后台线程调用
-(void) runATask:(AsyncTaskTask *)task
{
	if(task.isCancelled)
		return;
	
	@synchronized(self)
	{
		NSValue* value = _dicThreadTasks[[NSValue valueWithNonretainedObject:[NSThread currentThread]]];
		if(value && [value isEqualToValue:[NSValue valueWithNonretainedObject:nil]]==NO)
			NSLog(@"broken");
		_dicThreadTasks[[NSValue valueWithNonretainedObject:[NSThread currentThread]]] = [NSValue valueWithNonretainedObject:task];
	}

	@try {
		task.object = task.taskBlock();
	}
	@catch (NSException *exception) {
		NSLog(@"%@", exception);
	}
	@finally {
		;
	}

	@synchronized(self)
	{
		_dicThreadTasks[[NSValue valueWithNonretainedObject:[NSThread currentThread]]] = [NSValue valueWithNonretainedObject:nil];
	}
	
	if(task.isCancelled)
		return;
	
	//任务完成后提交到主线程
	[self performSelectorOnMainThread:@selector(taskFinished:) withObject:task waitUntilDone:NO];
}

-(AsyncTaskTask*)taskInThread:(NSThread*)thread
{
	@synchronized(self)
	{
		NSValue* value = _dicThreadTasks[[NSValue valueWithNonretainedObject:thread]];
		return value.nonretainedObjectValue;
	}
}

//此方法只在主线程中被调用
-(void) taskFinished:(AsyncTaskTask*)task
{
	@synchronized(self)
	{
		if(task.isCancelled)//只要是Cancel掉的任务，都会进入arrayCancelledTasks队列中，然后其cancelledBlock会被调用。所以这里直接Return即可。
			return;
		if(task.state==AsyncTaskStateRun)
			concurrentTasksCount--;
		[arrayAllTasks removeObjectIdenticalTo:task];
		[arrayHotTasks removeObjectIdenticalTo:task];
		AsyncTaskGroup* group = dicGroups[task.group];
		[group.dicTasks removeObjectForKey:task.key];
	}

	if(task.finishedBlock)
		task.finishedBlock(task.object);
}

#pragma mark Load/Cancel

static int nextTaskId = 0;

-(void) putTaskWithKey:(id)taskKey group:(id)group taskBlock:(IDNAsyncTaskBlock)taskBlock finishedBlock:(IDNAsyncTaskFinishedBlock)finishedBlock cancelledBlock:(IDNAsyncTaskCancelledBlock)cancelledBlock
{
	if(taskBlock==nil)
		return;
	if(taskKey==nil)
	{
		taskKey = [NSString stringWithFormat:@"^$&IDNAsyncTask%d",nextTaskId++];
	}
	if(group==nil)
		group = [NSNull null];
	AsyncTaskTask* task	= [[AsyncTaskTask alloc] init];
	task.key = taskKey;
	task.group = group;
	task.taskBlock	= taskBlock;
	task.finishedBlock = finishedBlock;
	task.cancelledBlock = cancelledBlock;
	@synchronized(self)
	{
		AsyncTaskGroup* taskGroup = dicGroups[group];
		if(taskGroup==nil)
		{
			taskGroup = [[AsyncTaskGroup alloc] init];
			taskGroup.group = group;
			dicGroups[group] = taskGroup;
		}
		
		AsyncTaskTask* oldTask = taskGroup.dicTasks[taskKey];
		if(oldTask)
		{
			oldTask.isCancelled = TRUE;//取消旧任务
			[arrayCancelledTasks addObject:oldTask];
			[arrayAllTasks removeObjectIdenticalTo:oldTask];
			[arrayHotTasks removeObjectIdenticalTo:oldTask];
			if(isReportCancelledTasksSubmitted==NO)
			{
				isReportCancelledTasksSubmitted = YES;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self reportCancelledTasksOnMainThread];
				});
			}
		}
		taskGroup.dicTasks[taskKey] = task;

		[arrayAllTasks addObject:task];
		if([group isEqual:currentGroup])
			[arrayHotTasks addObject:task];
		
		if (isScheduleATaskSubmitted==NO) {
			isScheduleATaskSubmitted = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self scheduleATask];
			});
		}
	}
}

-(void) reportCancelledTasksOnMainThread
{
	NSArray* cancelledTasks;
	@synchronized(self)
	{
		isReportCancelledTasksSubmitted = NO;
		if(arrayCancelledTasks.count)
		{
			cancelledTasks = arrayCancelledTasks;
			arrayCancelledTasks = [[NSMutableArray alloc] init];
		}
		for (AsyncTaskTask* task in cancelledTasks)
		{
			if(task.state==AsyncTaskStateRun)
				concurrentTasksCount--;
		}
	}
	for (AsyncTaskTask* task in cancelledTasks) {
		if(task.cancelledBlock)
			task.cancelledBlock();
	}
}

-(void) cancelTaskWithKey:(id)taskKey group:(id)group;
{
	if(taskKey==nil)
		return;
	
	if (group==nil)
		group = [NSNull null];

	@synchronized(self)
	{
		AsyncTaskGroup* taskGroup = dicGroups[group];
		AsyncTaskTask* task = taskGroup.dicTasks[taskKey];
		if(task==nil)
			return;

		task.isCancelled = YES;
		[arrayCancelledTasks addObject:task];
		[arrayAllTasks removeObjectIdenticalTo:task];
		[arrayHotTasks removeObjectIdenticalTo:task];
		[taskGroup.dicTasks removeObjectForKey:taskKey];
		
		if(isReportCancelledTasksSubmitted==NO)
		{
			isReportCancelledTasksSubmitted = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self reportCancelledTasksOnMainThread];
			});
		}
	}
}

-(void) cancelAllTasksInGroup:(id)group
{
	if (group==nil)
		group = [NSNull null];
	
	@synchronized(self)
	{
		AsyncTaskGroup* taskGroup = dicGroups[group];
		if(taskGroup.dicTasks.count==0)
			return;
		for (AsyncTaskTask* task in taskGroup.dicTasks.allValues)
		{
			task.isCancelled = YES;
			[arrayCancelledTasks addObject:task];
			[arrayAllTasks removeObjectIdenticalTo:task];
			[arrayHotTasks removeObjectIdenticalTo:task];
		}
//		[taskGroup.dicTasks removeAllObjects];
		[dicGroups removeObjectForKey:group];
		
		if(isReportCancelledTasksSubmitted==NO)
		{
			isReportCancelledTasksSubmitted = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self reportCancelledTasksOnMainThread];
			});
		}
	}
}

#pragma mark class methods

+ (void)putTask:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock
{
	[[IDNAsyncTask taskManager] putTaskWithKey:nil group:nil taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}
+ (void)putTask:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock group:(id)group
{
	[[IDNAsyncTask taskManager] putTaskWithKey:nil group:group taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}
+(void) putTaskWithKey:(id)taskKey group:(id)group task:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock
{
	[[IDNAsyncTask taskManager] putTaskWithKey:taskKey group:group taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

+(void) cancelTaskWithKey:(id)taskKey group:(id)group
{
	[[IDNAsyncTask taskManager] cancelTaskWithKey:taskKey group:group];
}

+(void) cancelAllTasksInGroup:(id)group
{
	[[IDNAsyncTask taskManager] cancelAllTasksInGroup:group];
}

+(BOOL) isTaskCancelled
{
	return [[IDNAsyncTask taskManager] taskInThread:[NSThread currentThread]].isCancelled;
}

@end
