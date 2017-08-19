//
//  UIViewController+IDNAlert.m
//  xiangyue3
//
//  Created by photondragon on 16/5/28.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import "UIViewController+IDNAlert.h"

@implementation UIViewController(IDNAlert)

- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
	  closeButtonTitle:(NSString*)closeButtonTitle
		  closeHandler:(void (^)())closeHandler
{
	if(closeButtonTitle.length==0)
		closeButtonTitle = @"关闭";
	[self alertWithTitle:title
				 message:message
	  defaultButtonTitle:closeButtonTitle
		  defaultHandler:closeHandler
			button1Title:nil
				handler1:nil
			button2Title:nil
				handler2:nil];
}

- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
		 okButtonTitle:(NSString*)okButtonTitle
			 okHandler:(void (^)())okHandler
	 cancelButtonTitle:(NSString*)cancelButtonTitle
		 cancelHandler:(void (^)())cancelHandler
{
	if(okButtonTitle.length==0)
		okButtonTitle = @"确定";
	if(cancelButtonTitle.length==0)
		cancelButtonTitle = @"取消";
	[self alertWithTitle:title
				 message:message
	  defaultButtonTitle:cancelButtonTitle
		  defaultHandler:cancelHandler
			button1Title:okButtonTitle
				handler1:okHandler
			button2Title:nil
				handler2:nil];
}

- (void)alertWithTitle:(NSString*)title
			   message:(NSString*)message
	defaultButtonTitle:(NSString*)defaultButtonTitle
		defaultHandler:(void (^)())defaultHandler
		  button1Title:(NSString*)button1Title
			  handler1:(void (^)())handler1
		  button2Title:(NSString*)button2Title
			  handler2:(void (^)())handler2
{
	if([[[UIDevice currentDevice] systemVersion] floatValue]<8.0)
		return;
	
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

	// 默认按钮
	if(defaultButtonTitle.length==0)
		defaultButtonTitle = @"关闭";
	UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:defaultButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		if(defaultHandler)
			defaultHandler();
	}];
	[alertController addAction:defaultAction];

	// 按钮1
	if(button1Title.length){
		UIAlertAction* action1 = [UIAlertAction actionWithTitle:button1Title style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			if(handler1)
				handler1();
		}];

		[alertController addAction:action1];
	}
	
	// 按钮1
	if(button2Title.length){
		UIAlertAction* action2 = [UIAlertAction actionWithTitle:button2Title style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			if(handler2)
				handler2();
		}];

		[alertController addAction:action2];
	}
	
	[self presentViewController:alertController animated:YES completion:nil];
}

@end
