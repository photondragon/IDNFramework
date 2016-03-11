//
//  IDNJumpManage.h
//  IDNFramework
//
//  Created by photondragon on 16/3/8.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 应用程序内页面跳转管理器

 jumpKey标识了要跳转的目标，可以自由定义，通过isEqual:方法比较key是否相等。
 本类的使用方法与NSNotificationCenter类似，JumpKey相当于NotificationName，
 handler相当于observer，action就是selector。
 内部不包含任何线程处理的代码，线程安全问题请自行解决。
 使用建议：程序应该重载此类，示例代码在本文件末尾。
 */
@interface IDNJumpManage : NSObject

+ (nonnull instancetype)sharedInstance;

/**
 *  添加跳转处理handler。
 *  对handler是弱引用，无需手动删除。如果handler对象释放了，delHandler:方法会自动被调用
 *  同一个jumpKey同一时间可以有多个处理的handler-action对。
 *
 *  @param jumpKey 跳转Key
 *  @param handler 处理跳转的对象。弱引用
 *  @param action  处理跳转的方法。格式：- (void)recvJumpKey:(id)jumpKey params:(NSDictionary*)params;
 */
- (void)addHandler:(nonnull id)handler action:(nonnull SEL)action jumpKey:(nonnull id)jumpKey;
/**
 *  删除跳转处理handler。
 *
 *  @param handler 跳转处理handler。
 *  @param action  跳转处理方法。如果为空，则删除所有同时包含jumpKey-handler的处理handler
 *  @param jumpKey 跳转Key。不可为空
 */
- (void)delHandler:(nonnull id)handler action:(nullable SEL)action jumpKey:(nonnull id)jumpKey;

/**
 *  发出跳转通知
 *
 *  @param jumpKey 跳转Key
 *  @param params  跳转参数（自定义）
 */
- (void)jumpWithKey:(nonnull id)jumpKey params:(nullable NSDictionary*)params;

#pragma mark - 延迟跳转相关，可用于实现登录后再跳转的功能

@property(nonatomic,strong,readonly,nullable) id delayJumpKey;
@property(nonatomic,strong,readonly,nullable) NSDictionary* delayJumpParams;

/**
 *  设置延迟跳转的Key与参数
 *
 *  @param jumpKey 延迟跳转的Key
 *  @param params  延迟跳转的参数
 */
- (void)delayJumpWithKey:(nonnull id)jumpKey params:(nullable NSDictionary*)params;
/**
 *  如果设置了延迟跳转的Key与参数，则跳转（并且清除延迟跳转的Key与参数）；否则什么也不做。
 */
- (void)jumpIfDelayed;

@end

#pragma mark - 子类示例

/**
 @sample 子类示例

// 特定应用程序的jumpKey的定义，写在头文件中
#define JumpKeyUser		@"JumpKeyUser"
#define JumpKeyGroup	@"JumpKeyGroup"

@interface JumpManageSample : IDNJumpManage

// 根据URL中的参数，生成对应的JumpKey并分发的方法
- (void)dispatchJumpsWithUrlParams:(NSDictionary*)urlParams;

@end

@implementation JumpManageSample

- (void)dispatchJumpsWithUrlParams:(NSDictionary*)urlParams
{
	NSString* jumpKey = nil;
	NSDictionary* jumpParams = nil;
	NSString* type = urlParams[@"type"];
	if([type isEqualToString:@"user"])
	{
		jumpKey = JumpKeyUser;
		jumpParams = @{@"uid":urlParams[@"uid"]};
	}
	else if([type isEqualToString:@"group"])
	{
		jumpKey = JumpKeyGroup;
		jumpParams = @{@"gid":urlParams[@"gid"]};
	}

	if(jumpKey==nil)
	{
		NSLog(@"无法识别的跳转信息: %@", urlParams);
		return;
	}

	NSLog(@"发出跳转通知 %@", jumpKey);
	[self jumpWithKey:jumpKey params:jumpParams];
}

 */