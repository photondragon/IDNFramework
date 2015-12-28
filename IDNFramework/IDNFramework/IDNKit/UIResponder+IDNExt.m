//
//  UIResponder+IDNExt.m
//  IDNFramework
//
//  Created by photondragon on 15/12/3.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIResponder+IDNExt.h"
#import <objc/runtime.h>
#import "NSObject+IDNCustomObject.h"

@implementation UIResponder(IDNExt)

#pragma mark - 禁用菜单

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Method oldMethod = class_getInstanceMethod(self, @selector(canPerformAction:withSender:));
		Method newMethod = class_getInstanceMethod(self, @selector(idn_canPerformAction:withSender:));
		method_exchangeImplementations(oldMethod, newMethod);
	});
}

- (BOOL)idn_canPerformAction:(SEL)action withSender:(id)sender
{
	if(self.disablePopoverMenu)
		return NO;
	return [self idn_canPerformAction:action withSender:sender];
}

- (BOOL)disablePopoverMenu
{
	return [[self customObjectForKey:@"UITextView(IDNExt)disablePopoverMenu"] boolValue];
}
- (void)setDisablePopoverMenu:(BOOL)disablePopoverMenu
{
	[self setCustomObject:@(disablePopoverMenu) forKey:@"UITextView(IDNExt)disablePopoverMenu"];
}

@end
