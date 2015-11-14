/** @file IDNTask.h
 */

#import <Foundation/Foundation.h>

typedef id (^IDNTaskBlock)(void);
typedef void (^IDNTaskFinishedBlock)(id obj);
typedef void (^IDNTaskCancelledBlock)();

/// 异步任务
/** 任务在后台主线程中执行，通知Block都是在主线程中执行的 */
@interface IDNTask : NSObject

+ (id)putTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;
+ (id)putTask:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock group:(id)group;

/**
// 提交一个任务。taskKey代表任务名（建议用NSString或NSNumber），group表示任务所属的组（建议用NSString），同一个组内任务名不可重复，如果提交一个重复任务，则之前提交的那个任务会被取消。
// taskBlock是具体任务的实现，将在后台线程中执行；任务执行完毕后会在主线程执行finishedBlock；如果任务取消，会在主线程执行cancelledBlock。
// group可以是NSValue/NSNumber/NSString/NSDate/NSNull类型；如果是其它类型，则转化为[NSValue valueWithNonretainedObject:group]，也就是说不会强引用自定义group对象。默认组是NSNull。如果group==nil，则视为NSNull。
 @return 返回taskKey。如果taskBlock==nil，函数返回nil
 */
+ (id)putTaskWithKey:(id)taskKey group:(id)group task:(IDNTaskBlock)taskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;

/**
 带网络请求的任务
 */
+ (id)putTaskWithRequest:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;
+ (id)putTaskWithRequest:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock group:(id)group;
+ (id)putTaskWithKey:(id)taskKey group:(id)group request:(NSURLRequest*)request urlTask:(id (^)(NSError*requestError, NSData* responseData, NSURLResponse* response))urlTaskBlock finished:(IDNTaskFinishedBlock)finishedBlock cancelled:(IDNTaskCancelledBlock)cancelledBlock;

+ (NSURLRequest*)requestGetFromUrl:(NSString*)url; //简便方法。生成一个Get方式的请求

+ (void)cancelTaskWithKey:(id)taskKey group:(id)group;
+ (void)cancelAllTasksInGroup:(id)group;

+ (BOOL)isTaskCancelled;//在taskBlock中调用，检测当前任务是否被取消了。在其它地方调用是无效的，总是返回NO。


@end



