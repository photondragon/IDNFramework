//
//  IDNListItemCenter.h
//  testItemCenter
//
//  Created by photondragon on 15/7/18.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDNListItemCenterObserver;

// 功能类似IDNItemCenter，适用于服务器只提供了一次获取整个列表的接口的情况
@interface IDNListItemCenter : NSObject

+ (instancetype)defaultCenter;

- (void)getItemWithID:(id)objID callback:(void (^)(id item, NSError* error))callback; //item通过callback异步返回，callback总是在主线程被调用

//- (void)deleteItemWithItemIDs:(NSArray*)itemIDs; //只删除本地的，不会发起网络请求
- (void)checkAndUpdateLocalItems:(NSArray*)items; // 手动更新。检测items（是否修改、过期）并保存到本地
- (void)forceReload; //强制刷新（从服务器获取）

@property NSUInteger memoryCacheCountLimit; //内部自带的内存缓存的最大可存储的items的个数。0表示无限制。默认0

#pragma mark Observers

- (void)addItemUpdatedObserver:(id<IDNListItemCenterObserver>)observer;//添加观察者。不会增加observer对象的引用计数，当observer对象引用计数变为0时，会自动删除observer，无需手动删除。
- (void)delItemUpdatedObserver:(id<IDNListItemCenterObserver>)observer;//删除观察者

#pragma mark 需要子类重载的方法

/* 子类应该重载此方法，实现根据itemIDs数组从本地获取items。
 如果有的ID有，有的ID没有，那么只返回本地有的Items。
 此方法总是在后台线程中被调用，已加锁。
 @return 返回包含items的字典，key为itemID，value为item
 */
- (NSDictionary*)itemsFromLocalWithIDs:(NSArray*)itemIDs;

- (void)clearAllLocalItems;

/* 子类应该重载此方法，实现将由参数传入的items保存在本地（内存、文件或者数据库中）
 此方法总是在后台线程中被调用，已加锁。
 */
- (void)updateLocalItems:(NSArray*)items;

- (void)deleteLocalItemWithItemIDs:(NSArray*)itemIDs;

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

/* 子类应该重载此方法，从服务器获取items列表。
 此方法总是在后台线程中被调用，未加锁。
 */
- (void)fetchItemsFromServerWithCallback:(void (^)(NSDictionary* dicItems, NSError* error))callback;

@end

@protocol IDNListItemCenterObserver <NSObject>
@optional
// 此函数总是在主线程被调用
- (void)listItemCenter:(IDNListItemCenter*)listItemCenter updatedItem:(id)item; //信息更新（修改，首次获取）了

@end
