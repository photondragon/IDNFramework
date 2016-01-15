//
//  UIViewController+IDNStatusBar.m
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIViewController+IDNStatusBar.h"
#import <objc/runtime.h>

@implementation UIViewController(IDNStatusBar)

static UIStatusBarStyle dreferredStatusBarStyleDefaultValue = UIStatusBarStyleDefault;

+ (void)setPreferredStatusBarStyleDefaultValue:(UIStatusBarStyle)defaultValue
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method oldMethod = class_getInstanceMethod(self, @selector(preferredStatusBarStyle));
		Method newMethod = class_getInstanceMethod(self, @selector(preferredStatusBarStyleIDNStatusBar));
		method_exchangeImplementations(oldMethod, newMethod);
	}
	
	dreferredStatusBarStyleDefaultValue = defaultValue;
}

- (UIStatusBarStyle)preferredStatusBarStyleIDNStatusBar
{
	return dreferredStatusBarStyleDefaultValue;
}

@end
