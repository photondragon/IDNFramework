//
//  UIView+IDNKeyboard.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIView+IDNKeyboard.h"
#import <objc/runtime.h>

@implementation UIView(IDNKeyboard)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfUIViewIDNKeyboardBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	if(dic[@"block"]==nil)
		return;
	if(newWindow)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	}
}

- (void (^)(CGFloat,double,UIViewAnimationCurve))keyboardFrameWillChangeBlock
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	return dic[@"block"];
}

- (void)setKeyboardFrameWillChangeBlock:(void (^)(CGFloat, double, UIViewAnimationCurve))keyboardFrameWillChangeBlock
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	if(keyboardFrameWillChangeBlock)
	{
		if(dic[@"block"]==nil && self.window)//之前没有设置Block而self已经在视图树中显示
		{
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
		}
		dic[@"block"] = keyboardFrameWillChangeBlock;
	}
	else
	{
		if(dic[@"block"] && self.window)//已经设置Block而且self已经在视图树中显示
			[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
		[dic removeObjectForKey:@"block"];
	}
}

- (void)viewKeyboardWillChangeFrame:(NSNotification*)note
{
	NSDictionary *userInfo = [note userInfo];
	
	NSTimeInterval animationDuration;
	NSNumber *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	animationDuration = [animationDurationValue doubleValue];
	//	[animationDurationValue getValue:&animationDuration];
	NSNumber *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	UIViewAnimationCurve animationCurve = [animationCurveValue integerValue];
	
	NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [self convertRect:[aValue CGRectValue] fromView:nil];//获取键盘坐标，并由屏幕坐标转为view的坐标
	CGRect containerRect = self.bounds;
	CGFloat bottomDistance = containerRect.size.height - keyboardRect.origin.y;
	
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	if(dic[@"block"])
	{
		void (^keyboardFrameWillChangeBlock)(CGFloat,double,UIViewAnimationCurve) = dic[@"block"];
		keyboardFrameWillChangeBlock(bottomDistance,animationDuration,animationCurve);
	}
}

@end
