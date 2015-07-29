//
//  IDNFixedList.h
//

#import <Foundation/Foundation.h>

@protocol IDNFixedListObserver;

// 封装了分段获取固定列表的算法的类。适用于只在列表首部增加条目，不会修改删除条目，顺序不变的列表
@interface IDNFixedList : NSObject

@property(nonatomic,strong,readonly) NSArray* list;
@property(nonatomic,readonly) BOOL reachEnd; //是否取到了列表末尾。这个属性不会影响moreWithFinishedBlock:方法

- (void)refreshWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //获取列表前一段
- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //获取列表后一段

// observers未加锁，只能在主线程添加或删除观察者，也不得在观察者通知方法里添加删除观察者。
- (void)addFixedListObserver:(id<IDNFixedListObserver>)observer; //对observer是weak型弱引用，所以无需手动删除fixedListObserver。
- (void)delFixedListObserver:(id<IDNFixedListObserver>)observer;

#pragma mark 子类应该重载的方法（外部不要调用这些方法）

/**
 获取列表尾部一段条目，通过callback返回数据。
 @param tailID 当前列表中最后一个条目。tailID==nil表示首次调用，此时应该获取列表第一段条目。
 @param callback 子类的实现中，当获取到数据（或失败）时，必须调用callback，传入获取到的条目或者error，否则列表会永远处于loadingTail状态，无法再发出新的more请求。
 */
- (void)queryAfterTailID:(id)tailID callback:(void (^)(NSArray* ids, BOOL reachEnd, NSError* error))callback;

/**
 获取列表首部一段条目，通过callback返回数据。
 @param headID 当前列表中第一个条目。headID不可能为nil。
 @param callback 子类的实现中，当获取到数据（或失败）时，必须调用callback，传入获取到的条目或者error，否则列表会永远处于loadingTail状态，无法再发出新的refresh请求。
 */
- (void)queryBeforeHeadID:(id)headID callback:(void (^)(NSArray* ids, BOOL needsReload, NSError* error))callback;

@end

@protocol IDNFixedListObserver <NSObject>
@optional
/**
 当FixedList列表条目发生变化时，此通知方法会在主线程被调用，可以用于更新TableView的显示。
 三个参数是NSNumber的数组，分别包含删除的条目的位置索引、添加的条目的位置索引和修改的条目的位置索引。
 位置索引的值与操作顺序相关，先删除（从后向前），再添加（从前往后），最后修改。
 调用-more或-refresh可能会使用列表发生变化，此方法的调用时机是在finishedBlock之前。
 */
- (void)fixedList:(IDNFixedList*)fixedList deletedIndics:(NSArray*)deletedIndics addedIndics:(NSArray*)addedIndics modifiedIndics:(NSArray*)modifiedIndics;

@end
