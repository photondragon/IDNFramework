/** @file IDNTask.m
 内部使用NSOperationQueue来实现多线程操作
 */

#import "IDNTask.h"
#include <sys/sysctl.h>

#define HotTaskRatio 5 //每执行HotTaskRatio个任务中，只有一个是普通任务，其余都是高优先级任务

enum IDNTaskState
{
	IDNTaskStateRequest=-1,
	IDNTaskStateWaiting=0,
	IDNTaskStateRun, //正在执行或执行完成
};

@interface IDNTask()

@property(nonatomic,strong) id key;
@property(nonatomic,strong) id group;
@property(nonatomic,strong) id object;
@property(atomic) enum IDNTaskState state; //任务的当前状态
@property(atomic) BOOL isCancelled;//任务是否已取消
@property(nonatomic,strong) NSURLRequest* request;
@property(nonatomic,strong) NSError* requestError;
@property(nonatomic,strong) NSMutableData* responseData;
@property(nonatomic,strong) NSURLResponse* response;
@property(nonatomic,strong) id (^urlTaskBlock)(NSError* requestError, NSData* responseData, NSURLResponse* response); // 如果requestError非空，表示出错，此时responseData/response可能有，也可能没有（比如下载一半断网）
@property(nonatomic,strong) IDNTaskFinishedBlock finishedBlock;
@property(nonatomic,strong) IDNTaskCancelledBlock cancelledBlock;

@property(nonatomic,strong) NSURLConnection* connection;

- (void)startRequest;
- (void)cancelRequest;

@end

@interface IDNTaskGroup : NSObject
@property(nonatomic,strong) id group; //组名
@property(nonatomic,strong) NSMutableDictionary* dicTasks;//组内任务
@end
@implementation IDNTaskGroup

- (instancetype)init
{
	self = [super init];
	if (self) {
		_dicTasks = [[NSMutableDictionary alloc] init];
	}
	return self;
}

@end

@interface IDNTaskManage: NSObject
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
@property(nonatomic) NSInteger maxConcurrentRequests; //最大并发网络请求数
@property(nonatomic,strong) NSMutableDictionary* dicThreadTasks; //线程对应的任务
-(void) cancelTaskWithKey:(id)taskKey group:(id)group;
-(void) cancelAllTasksInGroup:(id)group;
+(IDNTaskManage*)taskManager;
@end

@implementation IDNTaskManage

+(IDNTaskManage*)taskManager
{
	static IDNTaskManage* taskManager = nil;
	if(taskManager==nil)
	{
		@synchronized(self)
		{
			if(taskManager==nil)
			{
				taskManager = [[IDNTaskManage alloc] initPrivate];
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
		_maxConcurrentTasks = [self countOfCores]+1;
		_maxConcurrentRequests = 16;
	}
	return self;
}

- (unsigned int)countOfCores //CPU核心个数
{
	unsigned int ncpu;
	size_t len = sizeof(ncpu);
	sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
	
	return ncpu;
}

#pragma mark Task

+(NSOperationQueue*) operationQueue
{
	static NSOperationQueue* operationQueue = nil;
	
	if(operationQueue==nil)
	{
		@synchronized(self)
		{
			if(operationQueue==nil)
			{
				operationQueue = [[NSOperationQueue alloc] init];
				[operationQueue setName:@"IDNTaskQueue"];
				operationQueue.maxConcurrentOperationCount = [IDNTaskManage taskManager].maxConcurrentTasks;
			}
		}
	}
	return operationQueue;
}

- (int)scheduleATask
{
	static int n=0;
	int count = 0;
//	while (isScheduleATaskSubmitted) {
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
				
				IDNTask* aTask = nil;
				
				if (isHot) //Hot任务
				{
					for (IDNTask* task in arrayHotTasks) {
						if (task.state==IDNTaskStateWaiting) {
							aTask = task;
							break;
						}
					}
					if(aTask==nil)//没有Hot任务了
						isHot = NO;
				}
				if(isHot==NO) //普通任务
				{
					for (IDNTask* task in arrayAllTasks) {
						if (task.group!=currentGroup && task.state==IDNTaskStateWaiting) {
							aTask = task;
							break;
						}
					}
				}
				
				if(aTask==nil)
					break;
				
				aTask.state = IDNTaskStateRun; //必须在加锁区内设置这个属性，否则可能导致另一个scheduleATask线程也获取到这个任务
				concurrentTasksCount++;
				NSInvocationOperation* op	= [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runATask:) object:aTask];
				[[IDNTaskManage operationQueue] addOperation:op];
				count++;
			}
			
			if (concurrentTasksCount<arrayAllTasks.count) { // 表示还有任务待处理 //死循环风险？？？
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01), dispatch_get_main_queue(), ^{
					[self scheduleATask];
				});
			}
			else
				isScheduleATaskSubmitted = NO;
		} //end @synchronized(self)
//	}
	return count;
}

//此函数由后台线程调用
- (void)runATask:(IDNTask *)task
{
	if(task.isCancelled)
		return;
	
	NSValue* threadKey = [NSValue valueWithNonretainedObject:[NSThread currentThread]];
	@synchronized(self)
	{
		// 设置当前线程运行的是哪个任务
		_dicThreadTasks[threadKey] = [NSValue valueWithNonretainedObject:task];
	}
	
	@try {
		task.object = task.urlTaskBlock(task.requestError, task.responseData, task.response);
	}
	@catch (NSException *exception) {
		NSLog(@"IDNTask 执行任务异常(key=%@, group=%@): %@", task.key, task.group, exception);
	}
	@finally {
		;
	}
	
	@synchronized(self)
	{
		_dicThreadTasks[threadKey] = [NSValue valueWithNonretainedObject:nil];
	}
	
	if(task.isCancelled)
		return;
	
	//任务完成后提交到主线程
	[self performSelectorOnMainThread:@selector(taskFinished:) withObject:task waitUntilDone:NO];
}

-(IDNTask*)taskInThread:(NSThread*)thread
{
	@synchronized(self)
	{
		NSValue* value = _dicThreadTasks[[NSValue valueWithNonretainedObject:thread]];
		return value.nonretainedObjectValue;
	}
}

//此方法只在主线程中被调用
-(void) taskFinished:(IDNTask*)task
{
	@synchronized(self)
	{
		if(task.isCancelled)//只要是Cancel掉的任务，都会进入arrayCancelledTasks队列中，然后其cancelledBlock会被调用。所以这里直接Return即可。
			return;
		if(task.state==IDNTaskStateRun)
			concurrentTasksCount--;
		[arrayAllTasks removeObjectIdenticalTo:task];
		[arrayHotTasks removeObjectIdenticalTo:task];
		IDNTaskGroup* group = dicGroups[task.group];
		[group.dicTasks removeObjectForKey:task.key];
	}
	
	if(task.finishedBlock)
		task.finishedBlock(task.object);
}

#pragma mark Load/Cancel

static int nextTaskId = 0;

- (id)putTaskWithKey:(id)taskKey group:(id)group taskBlock:(IDNTaskBlock)taskBlock finishedBlock:(IDNTaskFinishedBlock)finishedBlock cancelledBlock:(IDNTaskCancelledBlock)cancelledBlock
{
	if(taskBlock==nil)
		return nil;
	return [self putTaskWithKey:taskKey group:group request:nil urlTaskBlock:^id(NSError*requestError, NSData *responseData, NSURLResponse *response) {
		return taskBlock();
	} finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

- (id)putTaskWithKey:(id)taskKey group:(id)group request:(NSURLRequest*)request urlTaskBlock:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finishedBlock:(IDNTaskFinishedBlock)finishedBlock cancelledBlock:(IDNTaskCancelledBlock)cancelledBlock
{
	if(urlTaskBlock==nil)
		return nil;
	if(taskKey==nil)
	{
		taskKey = [NSString stringWithFormat:@"^$&IDNTask%d",nextTaskId++];
	}
	if(group==nil)
		group = [NSNull null];
	else if([group isKindOfClass:[NSString class]]==NO &&
			[group isKindOfClass:[NSNumber class]]==NO &&
			[group isKindOfClass:[NSValue class]]==NO &&
			[group isKindOfClass:[NSDate class]]==NO &&
			[group isKindOfClass:[NSNull class]]==NO)
		group = [NSValue valueWithNonretainedObject:group];
	IDNTask* task	= [[IDNTask alloc] init];
	task.key = taskKey;
	task.group = group;
	task.request = request;
	task.urlTaskBlock	= urlTaskBlock;
	task.finishedBlock = finishedBlock;
	task.cancelledBlock = cancelledBlock;
	
	if(request)
	{
		task.state = IDNTaskStateRequest;
		[task startRequest];
	}
	@synchronized(self)
	{
		IDNTaskGroup* taskGroup = dicGroups[group];
		if(taskGroup==nil)
		{
			taskGroup = [[IDNTaskGroup alloc] init];
			taskGroup.group = group;
			dicGroups[group] = taskGroup;
		}
		
		IDNTask* oldTask = taskGroup.dicTasks[taskKey];
		if(oldTask)
		{
			oldTask.isCancelled = TRUE;//取消旧任务
			[oldTask cancelRequest];
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
	return taskKey;
}

- (void)reportCancelledTasksOnMainThread
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
		for (IDNTask* task in cancelledTasks)
		{
			if(task.state==IDNTaskStateRun)
				concurrentTasksCount--;
		}
	}
	for (IDNTask* task in cancelledTasks) {
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
		IDNTaskGroup* taskGroup = dicGroups[group];
		IDNTask* task = taskGroup.dicTasks[taskKey];
		if(task==nil)
			return;
		
		task.isCancelled = YES;
		[task cancelRequest];
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
		IDNTaskGroup* taskGroup = dicGroups[group];
		if(taskGroup.dicTasks.count==0)
			return;
		for (IDNTask* task in taskGroup.dicTasks.allValues)
		{
			task.isCancelled = YES;
			[task cancelRequest];
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

@end

@implementation IDNTask

+ (NSOperationQueue*)requestQueue
{
	static NSOperationQueue* requestQueue = nil;
	if(requestQueue==nil)
	{
		@synchronized(self)
		{
			if(requestQueue==nil)
			{
				requestQueue = [[NSOperationQueue alloc] init];
				[requestQueue setName:@"IDNTaskRequestsQueue"];
				requestQueue.maxConcurrentOperationCount = 1;
			}
		}
	}
	return requestQueue;
}

static int maxConcurrentRequests = 16;
static NSMutableArray* waitingConnections = nil; //存放的是IDNTaskTask
static NSMutableArray* startedConnections = nil;

+ (void)initialize
{
	if(waitingConnections==nil)
	{
		waitingConnections = [NSMutableArray new];
		startedConnections = [NSMutableArray new];
	}
}

+ (void)addRequestTask:(IDNTask*)requestTask
{
	@synchronized(waitingConnections)
	{
		if(maxConcurrentRequests==0 || startedConnections.count<maxConcurrentRequests)
		{
			NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:requestTask.request delegate:requestTask startImmediately:NO];
			if(connection==nil)//无法创建connection
			{
				requestTask.requestError = [NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"无法创建connection: %@", requestTask.request]}];
				requestTask.state = IDNTaskStateWaiting;
				return;
			}
			[connection setDelegateQueue:[self requestQueue]];
			[connection start];
			requestTask.connection = connection;
			[startedConnections addObject:requestTask];
			NSLog(@"start request");
		}
		else
		{
			[waitingConnections addObject:requestTask];
			NSLog(@"queue request");
		}
	}
}
+ (void)delRequestTask:(IDNTask*)requestTask
{
	@synchronized(waitingConnections)
	{
		if(requestTask.connection)
		{
			[requestTask.connection cancel];
			[requestTask.connection setDelegateQueue:nil];
			requestTask.connection = nil;
			[startedConnections removeObjectIdenticalTo:requestTask];
			[self startWaitingRequestTasks];
		}
		else
		{
			[waitingConnections removeObjectIdenticalTo:requestTask];
		}
	}
}

+ (void)startWaitingRequestTasks //start未开始的connections。受最大请求并发数限制，有些请求没有立即开始。
{
	// 不加锁，只在一处调用，并且上下文已加锁
	//@synchronized(waitingConnections)
	{
		NSInteger count = startedConnections.count < maxConcurrentRequests;
		if(waitingConnections.count && (maxConcurrentRequests==0 || count) )
		{
			[waitingConnections subarrayWithRange:NSMakeRange(0, count)];
			for (NSInteger i=count-1; i>=0; i--) {
				IDNTask* requestTask = waitingConnections[i];
				NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:requestTask.request delegate:requestTask startImmediately:NO];
				if(connection==nil)//无法创建connection
				{
					[waitingConnections removeObjectAtIndex:i];
					requestTask.requestError = [NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"无法创建connection: %@", requestTask.request]}];
					requestTask.state = IDNTaskStateWaiting;
					continue;
				}
				[connection setDelegateQueue:[self requestQueue]];
				[connection start];
				requestTask.connection = connection;
				[startedConnections addObject:requestTask];
				[waitingConnections removeObjectAtIndex:i];
			}
		}
	}
}

- (void)startRequest
{
	if(_request==nil)
		return;
	[IDNTask addRequestTask:self];
}

- (void)cancelRequest
{
	if(_request==nil)
		return;
	[IDNTask delRequestTask:self];
	// 取消请求不是Error
//	self.requestError = [NSError errorWithDomain:NSStringFromClass(self.class) code:0 userInfo:@{NSLocalizedDescriptionKey:@"请求取消"}];
}

#pragma mark NSURLConnectionDataDelegate

//- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
//{
//	NSLog(@"%s", __func__);
//}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//	NSLog(@"%s", __func__);
	self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
//	NSLog(@"%s", __func__);
	if(_responseData==nil)
		_responseData = [NSMutableData new];
	[_responseData appendData:data];
}

//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
//{
//	NSLog(@"%s", __func__);
//}

//- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten
//totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
//{
//	NSLog(@"%s", __func__);
//}

//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
//{
//	NSLog(@"%s", __func__);
//}

// 请求成功
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//	NSLog(@"%s", __func__);
	[IDNTask delRequestTask:self];
	self.state = IDNTaskStateWaiting;
}

// 请求失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
//	NSLog(@"%s", __func__);
	[IDNTask delRequestTask:self];
	self.requestError = error;
	self.state = IDNTaskStateWaiting;
}


#pragma mark class methods

+ (id)putTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock
{
	return [[IDNTaskManage taskManager] putTaskWithKey:nil group:nil taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}
+ (id)putTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock group:(id)group
{
	return [[IDNTaskManage taskManager] putTaskWithKey:nil group:group taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}
+ (id)putTaskWithKey:(id)taskKey group:(id)group task:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock
{
	return [[IDNTaskManage taskManager] putTaskWithKey:taskKey group:group taskBlock:taskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

+ (id)putTaskWithRequest:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock
{
	return [[IDNTaskManage taskManager] putTaskWithKey:nil group:nil request:request urlTaskBlock:urlTaskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

+ (id)putTaskWithRequest:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock group:(id)group
{
	return [[IDNTaskManage taskManager] putTaskWithKey:nil group:group request:request urlTaskBlock:urlTaskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

+ (id)putTaskWithKey:(id)taskKey group:(id)group request:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock
{
	return [[IDNTaskManage taskManager] putTaskWithKey:taskKey group:group request:request urlTaskBlock:urlTaskBlock finishedBlock:finishedBlock cancelledBlock:cancelledBlock];
}

+(void) cancelTaskWithKey:(id)taskKey group:(id)group
{
	[[IDNTaskManage taskManager] cancelTaskWithKey:taskKey group:group];
}

+(void) cancelAllTasksInGroup:(id)group
{
	[[IDNTaskManage taskManager] cancelAllTasksInGroup:group];
}

+(BOOL) isTaskCancelled
{
	return [[IDNTaskManage taskManager] taskInThread:[NSThread currentThread]].isCancelled;
}

+ (NSURLRequest*)requestGetFromUrl:(NSString *)url
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	request.timeoutInterval = 30.0;
	request.HTTPMethod = @"GET";
	return request;
}
@end

