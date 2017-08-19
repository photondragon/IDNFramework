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

- (void)setCornerRadius:(CGFloat)cornerRadius
{
	self.layer.cornerRadius = cornerRadius;
}
- (CGFloat)cornerRadius
{
	return self.layer.cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor
{
	self.layer.borderColor = borderColor.CGColor;
}
- (UIColor*)borderColor
{
	return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
	self.layer.borderWidth = borderWidth;
}
- (CGFloat)borderWidth
{
	return self.layer.borderWidth;
}


@end
