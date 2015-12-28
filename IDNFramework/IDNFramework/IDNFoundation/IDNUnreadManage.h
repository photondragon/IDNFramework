//
//  IDNUnreadManage.h
//  IDNFrameworks
//
//  Created by photondragon on 15/7/25.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDNUnreadManageObserver;

// 该类是线程安全的
@interface IDNUnreadManage : NSObject

- (instancetype)initWithFile:(NSString*)filePath;

@property(nonatomic,strong,readonly) NSString* filePath;

- (void)setUnreadCount:(NSInteger)unreadCount forKey:(NSString*)key; //unreadCount>=0。小于0则认为是0
- (void)addUnreadCount:(NSInteger)addCount forKey:(NSString*)key; // addCount可为负，如果结果小于0，则改为0

- (void)addSubKey:(NSString*)subKey forKey:(NSString*)key; //设置key之间了父子关系。这个关系相关信息不会持久化，需要在每次初始化时重新设置，也就是说这个关系可以随意改变（比如随版本升级而改变）。
- (NSInteger)unreadCountForKey:(NSString*)key; //只获取指定key的未读数，不包括子孙key的。
- (NSInteger)allUnreadCountForKey:(NSString*)key; //递归获取指定key及其子孙key的总未读数。

- (void)addUnreadObserver:(id<IDNUnreadManageObserver>)observer forKey:(NSString*)key; //注册指定key的未读数观察者，当该key及其子孙key的未读数改变时，会收到通知。这里的observer对象是weak型弱引用
- (void)delUnreadObserver:(id<IDNUnreadManageObserver>)observer forKey:(NSString*)key;

@end

@protocol IDNUnreadManageObserver <NSObject>

- (void)unreadManager:(IDNUnreadManage*)unreadManager unreadCountChangedForKey:(NSString*)key;

@end