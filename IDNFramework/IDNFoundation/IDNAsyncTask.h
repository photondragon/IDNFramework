/** @file IDNAsyncTask.h
 */

#import <Foundation/Foundation.h>

typedef id (^IDNAsyncTaskBlock)(void);
typedef void (^IDNAsyncTaskFinishedBlock)(id obj);
typedef void (^IDNAsyncTaskCancelledBlock)();

/// 异步任务
/** 任务在后台主线程中执行，通知Block都是在主线程中执行的 */
@interface IDNAsyncTask : NSObject

+ (void)putTask:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock;
+ (void)putTask:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock group:(id)group;
// 提交一个任务。taskKey代表任务名（建议用NSString或NSNumber），group表示任务所属的组（建议用NSString），同一个组内任务名不可重复，如果提交一个重复任务，则之前提交的那个任务会被取消。
// taskBlock是具体任务的实现，将在后台线程中执行；任务执行完毕后会在主线程执行finishedBlock；如果任务取消，会在主线程执行cancelledBlock。
+ (void)putTaskWithKey:(id)taskKey group:(id)group task:(IDNAsyncTaskBlock)taskBlock finished:(IDNAsyncTaskFinishedBlock)finishedBlock cancelled:(IDNAsyncTaskCancelledBlock)cancelledBlock;

+ (void)cancelTaskWithKey:(id)taskKey group:(id)group;
+ (void)cancelAllTasksInGroup:(id)group;

+ (BOOL)isTaskCancelled;//在taskBlock中调用，检测当前任务是否被取消了。在其它地方调用是无效的，总是返回NO。

@end



