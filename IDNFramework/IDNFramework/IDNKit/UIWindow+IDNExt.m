//
//  UIWindow+IDNExt.m
//  IDNFramework
//
//  Created by photondragon on 15/11/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIWindow+IDNExt.h"

@implementation UIWindow(IDNExt)

+ (UIWindow*)mainWindow
{
	return [UIApplication sharedApplication].keyWindow;
}

+ (UIViewController*)rootViewController
{
	return [UIApplication sharedApplication].keyWindow.rootViewController;
}

+ (UIViewController*)presentedViewController
{
	UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
	while (viewController.presentedViewController) {
		viewController = viewController.presentedViewController;
	}
	return viewController;
}

@end
