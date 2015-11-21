/** @file IDNTask.h
 */

#import <Foundation/Foundation.h>

typedef id (^IDNTaskBlock)(void); //任务Block
typedef id (^IDNURLTaskBlock)(NSError*requestError, NSData* responseData, NSURLResponse* response); //带网络请求的任务Block
typedef void (^IDNTaskFinishedBlock)(id obj); //任务完成Block
typedef void (^IDNTaskCancelledBlock)(); //任务取消Block

/// 异步任务，底层用一个线程池来执行任务
/** 任务在后台线程中执行，通知Block都是在主线程中执行的 */
@interface IDNTask : NSObject

/**
 *  提交一个任务，在后台线程执行，执行完成后在主线程通知
 *
 *  同时执行的任务个数为CPU核心个数+1
 *  taskBlock是具体任务的实现，将在后台线程中执行；任务执行完毕后会在主线程执行finishedBlock；如果任务取消，会在主线程执行cancelledBlock（此时finishedBlock不会执行）。
 *  参数key代表任务名称，参数group表示任务所属的组，同一个组内的任务key不可重复，如果提交一个重复的任务，则之前提交的那个任务会被取消。
 *  参数key建议使用NSString或NSNumber。
 *  参数group可以是NSValue/NSNumber/NSString/NSDate/NSNull类型；如果是其它类型，则转化为[NSValue valueWithNonretainedObject:group]，也就是说***不会强引用***自定义group对象。
 *  默认组是NSNull。如果group==nil，则视为NSNull。
 *
 *  @param taskBlock      任务Block，在后台线程执行。taskBlock的返回值就是finishedBlock的输入参数，可以返回nil
 *  @param finishedBlock  任务执行完成后要执行的Block，在主线程执行
 *  @param cancelledBlock 任务取消后要执行的Block，在主线程执行
 *  @param key            任务Key，可为nil。任务Key可以用于Cancel任务
 *  @param group          任务所属的组，可为nil。任务group可用于批量Cancel任务
 *
 *  @return 如果taskBlock==nil表示没有任务要执行，函数返回nil；否则返回任务Key，其值一般等于参数key，如果参数key==nil，则返回一个随机生成的key
 */
+ (id)submitTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock key:(id)key group:(id)group;
+ (id)submitTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;

/**
 *  提交带网络请求的异步任务
 *
 *  只比 - (id)submitTask:finished:cancelled:key:group: 多了一个request参数，用于发起网络请求，其它与其一致。
 *  网络请求与任务Block分离，网络请求最大并发数=16，任务Block最大并发数=CPU核心个数+1
 *  @param request        网络请求。网络请求的返回数据(NSData)或者错误信息(NSError)，以及响应(NSURLResponse)就是taskBlock的输入参数
 *  @param taskBlock      任务Block，在后台线程执行。taskBlock的返回值就是finishedBlock的输入参数，可以返回nil
 *  @param finishedBlock  任务执行完成后要执行的Block，在主线程执行
 *  @param cancelledBlock 任务取消后要执行的Block，在主线程执行
 *  @param key            任务Key，可为nil。任务Key可以用于Cancel任务
 *  @param group          任务所属的组，可为nil。任务group可用于批量Cancel任务
 *
 *  @return 如果taskBlock==nil表示没有任务要执行，函数返回nil；否则返回任务Key，其值一般等于参数key，如果参数key==nil，则返回一个随机生成的key
 */
+ (id)submitURLRequest:(NSURLRequest*)request task:(IDNURLTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock key:(id)key group:(id)group;
+ (id)submitURLRequest:(NSURLRequest*)request task:(IDNURLTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;

#pragma mark 任务取消

/// 取消指定任务。如果group==nil，则表示默认组
+ (void)cancelTaskWithKey:(id)taskKey group:(id)group;

/// 取消指定组中的所有任务。如果group==nil，则取消默认组中的所有任务
+ (void)cancelAllTasksInGroup:(id)group;

/// 在任务Block中调用，检测当前任务是否被取消了。在其它地方调用是无效的，总是返回NO
+ (BOOL)isTaskCancelled;

#pragma mark 便捷方法

+ (NSURLRequest*)requestHttpGetWithUrl:(NSString*)url; //简便方法。生成一个Get方式的HTTP请求，超时30s，忽略缓存

@end



