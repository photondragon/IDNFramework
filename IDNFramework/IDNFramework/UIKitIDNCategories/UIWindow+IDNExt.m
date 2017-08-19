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

- (void)addCustomSubview:(UIView*)customView
{
	[self addSubview:customView];
	customView.tag = WindowCustomViewTag;
}

- (void)removeAllCustomViews
{
	NSMutableArray* dels = [NSMutableArray new];
	for (UIView* view in self.subviews) {
		if(view.tag==WindowCustomViewTag)
			[dels addObject:view];
	}
	for (UIView* view in dels) {
		[view removeFromSuperview];
	}
}

@end
