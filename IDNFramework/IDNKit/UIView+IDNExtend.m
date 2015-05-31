//
//  UIView+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIView+IDNExtend.h"

@implementation UIView(IDNExtend)

+ (UIResponder*)findFirstResponderInView:(UIView*)view
{
	if (view.isFirstResponder) {
		return view;
	}
	for (UIView *subView in view.subviews) {
		UIResponder* responder = [self findFirstResponderInView:subView];
		if (responder)
			return responder;
	}
	return nil;
}

- (UIResponder*)findFirstResponder
{
	return [UIView findFirstResponderInView:self];
}

@end
