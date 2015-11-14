//
//  IDNItemCenter.h
//  testItemCenter
//
//  Created by photondragon on 15/7/18.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDNItemCenterObserver;

// 用于管理并缓存服务器数据到本地。
// 内部还带有一个内存缓存，不过外部无法直接访问。
// 线程安全
@interface IDNItemCenter : NSObject

// getItemWithID:和itemWithID:这两个方法都是用于获取item的，区别只是返回数据的方式有些不同
- (void)getItemWithID:(id)itemID callback:(void (^)(id item, NSError* error))callback; //item通过callback异步返回，callback总是在主线程被调用
- (id)itemWithID:(id)itemID callback:(void (^)(id item, NSError* error))callback; //如果内存缓存中有，则函数直接返回item（callback不会被调用）；如果内存缓存中没有，则item通过callback异步返回，callback总是在主线程被调用

- (void)checkAndUpdateLocalItems:(NSArray*)items; //手动更新。检测items（是否修改、过期）并保存到本地。如果有Items被更新，会通知观察者
- (void)checkAndUpdateLocalItems:(NSArray*)items ignoreObserver:(id<IDNItemCenterObserver>)ignoreObserver; // 手动更新。检测items（是否修改、过期）并保存到本地。如果有Items被更新，会通知观察者，但ignoreObserver指定的观察者不会收到通知。

- (void)forceReloadItems:(NSArray*)itemIds; //强制刷新（从服务器获取）

- (void)localQueryWithParams:(NSDictionary*)params callback:(void (^)(NSArray* items))callback; //查询本地Items。查询结果通过callback异步返回，callback总是在主线程被调用。这个操作不使用内存缓存。内部调用- (NSArray*)queryItemsFromLocalWithParams:(NSDictionary*)params来执行实际查询操作

@property NSUInteger memoryCacheCountLimit; //内部自带的内存缓存的最大可存储的items的个数。0表示无限制。默认0
@property BOOL combineRequests; //是否合并请求。如果设为NO，则每次网络请求只获取1个Item。默认YES。当服务器没有提供批量获取Items的接口时，应该设为NO

#pragma mark Observers

- (void)addItemUpdatedObserver:(id<IDNItemCenterObserver>)observer;//添加观察者。不会增加observer对象的引用计数，当observer对象引用计数变为0时，会自动删除observer，无需手动删除。
- (void)delItemUpdatedObserver:(id<IDNItemCenterObserver>)observer;//删除观察者

#pragma mark 需要子类重载的方法

/* 子类应该重载此方法，实现根据itemIDs数组从本地获取items。
 如果有的ID有，有的ID没有，那么只返回本地有的Items。
 此方法总是在后台线程中被调用，已加锁。
 @return 返回包含items的字典，key为itemID，value为item
 */
- (NSDictionary*)itemsFromLocalWithIDs:(NSArray*)itemIDs;

/* 子类应该重载此方法，实现本地自定义查询（根据ID以外字段查询）。
 当外部调用 - (void)localQueryWithParams:callback: 方法时，此方法会被调用。
 此方法总是在后台线程中被调用，已加锁。
 @param params 查询参数，就是外部调用 - (void)localQueryWithParams:callback: 方法时传入的parmas参数
 */
- (NSArray*)queryItemsFromLocalWithParams:(NSDictionary*)params;

/* 子类应该重载此方法，实现将由参数传入的items保存在本地（内存、文件或者数据库中）
 此方法总是在后台线程中被调用，已加锁。
 */
- (void)updateLocalItems:(NSArray*)items;

/* 子类应该重载此方法，检测传入的item是否过期（以决定是否需要重新从服务器获取），一般根据最近同步时间来判断
 此方法被调用时未加锁。
 */
- (BOOL)isItemExpired:(id)item;

/* 子类应该重载此方法，传入的两个参数oldItem和newItem它们的ID是相等的，需要比较两个item实例是否被修改过
 此方法被调用时未加锁。
 */
- (BOOL)isItemModified:(id)oldItem newItem:(id)newItem;

/* 子类应该重载此方法，根据传入的item返回其对应的ID
 此方法被调用时未加锁。
 */
- (id)idOfItem:(id)item;

/* 子类应该重载此方法，实现根据itemIDs数组从服务器获取items。
 此方法总是在后台线程中被调用，未加锁。
 */
- (void)fetchItemsFromServerWithIDs:(NSArray*)itemIDs callback:(void (^)(NSDictionary* dicItems, NSError* error))callback;

@end

@protocol IDNItemCenterObserver <NSObject>
@optional
// 此函数总是在主线程被调用
- (void)itemCenter:(IDNItemCenter*)itemCenter updatedItem:(id)item; //信息更新（修改，首次获取）了

@end
