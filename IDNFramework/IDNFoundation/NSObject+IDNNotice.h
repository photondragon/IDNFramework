//
//  NSObject+IDNNotice.h
//
//  Created by photondragon on 15/10/9.
//

#import <Foundation/Foundation.h>

/**
 *  在NSObject上实现观察者模式
 *  线程安全。不要在通知处理方法中订阅或取消订阅通知，否则会造成死锁
 */
@interface NSObject(IDNNotice)

/**
 *  发出通知
 *
 *  @param noticeName 通知名称
 *  @param customInfo 用户自定义数据
 */
- (void)notice:(nonnull NSString*)noticeName customInfo:(nullable id)customInfo;

/**
 *  订阅通知
 *
 *  @param noticeName 通知名称
 *  @param subscriber 订阅者，weak弱引用
 *  @param selector   格式为 - (void)receivedNoticeWithCustomInfo:(id)customInfo
 */
- (void)subscribeNotice:(nonnull NSString*)noticeName subscriber:(nonnull id)subscriber selector:(nonnull SEL)selector;

/**
 *  取消订阅通知
 *
 *  @param noticeName 通知名称
 *  @param subscriber 订阅者（观察者）
 *  @param selector   selector
 */
- (void)unsubscribeNotice:(nonnull NSString*)noticeName subscriber:(nullable id)subscriber selector:(nullable SEL)selector;
- (void)unsubscribeNotice:(nonnull NSString*)noticeName subscriber:(nullable id)subscriber;
- (void)unsubscribeNotice:(nonnull NSString*)noticeName;

@end
