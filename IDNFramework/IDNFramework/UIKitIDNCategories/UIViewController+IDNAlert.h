//
//  UIViewController+IDNAlert.h
//  xiangyue3
//
//  Created by photondragon on 16/5/28.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController(IDNAlert)

/**
*  弹框显示标题 + 消息 + 关闭按钮
*
*  @param title            标题。可为空
*  @param message          消息
*  @param closeButtonTitle 关闭按钮上的文本。如不设置，默认为“关闭”
*  @param closeHandler     按下关闭按钮后要执行的block。可为空
*/
- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
	  closeButtonTitle:(NSString*)closeButtonTitle
		  closeHandler:(void (^)())closeHandler;

/**
 *  弹框显示标题 + 消息 + 取消按钮 + 确定按钮
 *
 *  @param title             标题。可为空
 *  @param message           消息
 *  @param okButtonTitle     确定按钮上的文本。如不设置，默认为“确定”
 *  @param okHandler         按下确定按钮后要执行的block。可为空
 *  @param cancelButtonTitle 取消按钮上的文本。如不设置，默认为“取消”
 *  @param cancelHandler     按下取消按钮后要执行的block。可为空
 */
- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
		 okButtonTitle:(NSString*)okButtonTitle
			 okHandler:(void (^)())okHandler
	 cancelButtonTitle:(NSString*)cancelButtonTitle
		 cancelHandler:(void (^)())cancelHandler;

/**
 *  弹框显示标题 + 消息 + 一到三个按钮
 *
 *  @param title              标题。可为空
 *  @param message            消息
 *  @param defaultButtonTitle 默认按钮上的文本。如不设置，默认为“关闭”
 *  @param defaultHandler     按下默认按钮后要执行的block。可为空
 *  @param button1Title       按钮1的文本。如不设置，则不显示此按钮
 *  @param handler1           按下按钮1后要执行的block。可为空
 *  @param button2Title       按钮2的文本。如不设置，则不显示此按钮
 *  @param handler2           按下按钮2后要执行的block。可为空
 */
- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
	defaultButtonTitle:(NSString*)defaultButtonTitle
		defaultHandler:(void (^)())defaultHandler
		  button1Title:(NSString*)button1Title
			  handler1:(void (^)())handler1
		  button2Title:(NSString*)button2Title
			  handler2:(void (^)())handler2;

@end
