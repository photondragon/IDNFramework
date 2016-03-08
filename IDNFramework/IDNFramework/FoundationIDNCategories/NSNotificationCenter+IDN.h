//
//  NSNotificationCenter+IDN.h
//  IDNFramework
//
//  Created by photondragon on 16/3/8.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  NSNotificationCenter对observer和notiSender均是unsafe_unretain型引用，所以必须在observer和notiSender释放前调用removeObserver:删除观察者，否则程序就会崩溃。
 *  在实际开发中经常会出现忘记删除观察者的情况，导致程序崩溃
 *  本Category提供了一组新的方法，实现了对observer和notiSender的weak引用，所以无需手动删除观察者，观察者会在适当的时候**自动删除**。
 *  当然你也可以手动删除。
 */
@interface NSNotificationCenter(IDN)

//
/**
 *  addObserver:selector:name:object: 的weak引用版本
 *  添加Notification的观察者。
 *  （observer-notiName-notiSender三者的组合标识一个入口）
 *
 *  @param observer   观察者。weak引用，不可为nil
 *  @param selector
 *  @param notiName   通知名称
 *  @param notiSender 通知发送者。weak引用
 */
- (void)addWeakObserver:(nonnull id)observer selector:(nonnull SEL)selector name:(nullable NSString *)notiName object:(nullable id)notiSender;

/**
 *  删除与observer相关的所有条目
 *
 *  @param observer 观察者
 */
- (void)removeWeakObserver:(nonnull id)observer;
/**
 *  删除与“调用addWeakObserver:selector:name:object:方法传递的所有参数”完全一致的那个条目（只删除一条）
 */
- (void)removeWeakObserver:(nonnull id)observer name:(nullable NSString *)notiName object:(nullable id)notiSender;

@end
