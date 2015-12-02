//
//  UIViewController+IDNOrientation.m
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIViewController+IDNOrientation.h"
#import <objc/runtime.h>

@implementation UIViewController(IDNOrientation)

static UIInterfaceOrientationMask supportedInterfaceOrientationsDefaultValue = UIInterfaceOrientationMaskAllButUpsideDown;

+ (void)setSupportedInterfaceOrientationsDefaultValue:(UIInterfaceOrientationMask)defaultValue;
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method oldMethod = class_getInstanceMethod(self, @selector(supportedInterfaceOrientations));
		Method newMethod = class_getInstanceMethod(self, @selector(supportedInterfaceOrientationsIDNOrientation));
		method_exchangeImplementations(oldMethod, newMethod);
	}
	
	supportedInterfaceOrientationsDefaultValue = defaultValue;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsIDNOrientation
{
	return supportedInterfaceOrientationsDefaultValue;
}

@end
