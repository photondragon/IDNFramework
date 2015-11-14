//
//  NSObject+IDNEventHandle.h
//
//  Created by photondragon on 15/9/10.
//

#import <Foundation/Foundation.h>

/**
 *  为NSObject加上自定义事件处理机制，类似于UIControl的target-action机制。
 *  但同一时间一个事件只能设置一个处理方法或处理Block
 *  线程不安全，建议只在主线程调用
 */
@interface NSObject(IDNEventHandle)

/**
 *  触发指定事件
 *
 *  @param eventName  事件名称
 *  @param customInfo 用户自定义数据
 */
- (void)triggerEvent:(NSString*)eventName customInfo:(id)customInfo;

#pragma mark 设置/取消事件处理Handler

/**
 *  设置事件的处理target & selector
 *
 *  @param eventName 事件名称
 *  @param target    事件处理的target，weak弱引用
 *  @param selector  事件处理的selector，格式为 - (void)handleEventWithCustomInfo:(id)customInfo
 */
- (void)handleEvent:(NSString*)eventName target:(id)target selector:(SEL)selector; //target是弱引用，selector

/**
 *  设置事件的处理Handler
 *
 *  @param eventName 事件名称
 *  @param handler   事件处理的Block
 */
- (void)handleEvent:(NSString*)eventName handler:(void(^)(id customInfo))handler;

/**
 *  取消事件的处理Handler
 *
 *  @param eventName 事件名称
 */
- (void)stopHandleEvent:(NSString*)eventName;

#pragma mark 事件默认处理Handler

/**
 *  设置事件的默认处理target & selector
 *
 *  @param target    事件处理的target，weak弱引用
 *  @param selector  事件处理的selector，格式为 - (void)handleEvent:(NSString*)eventName customInfo:(id)customInfo
 */
- (void)setEventDefaultTarget:(id)target selector:(SEL)selector;

/**
 *  设置事件的默认处理Handler
 *
 *  @param eventName 事件名称
 *  @param handler   事件处理的Block
 */
- (void)setEventDefaultHandler:(void(^)(NSString* eventName, id customInfo))handler;

/**
 *  取消事件的默认处理Handler
 *
 *  @param eventName 事件名称
 */
- (void)unsetEventDefaultHandler;

@end
