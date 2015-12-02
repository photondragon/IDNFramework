//
//  UIButton+IDNColor.m
//  IDNFramework
//
//  Created by mahj on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIButton+IDNColor.h"
#import "NSObject+IDNCustomObject.h"

@implementation UIButton(IDNColor)

- (UIColor*)UIButton_IDNColor_savedBackgroundColor
{
	return [self customObjectForKey:@"UIButton_IDNColor_savedBackgroundColor"];
}
- (void)UIButton_IDNColor_SaveBackgroundColor:(UIColor*)color
{
	[self setCustomObject:color forKey:@"UIButton_IDNColor_savedBackgroundColor"];
}

#pragma mark - pressed color

- (UIColor*)backgroundColorHighlighted
{
	return [self customObjectForKey:@"UIButton_IDNColor_backgroundColorHighlighted"];
}
- (void)setBackgroundColorHighlighted:(UIColor *)backgroundColorHighlighted
{
	[self setCustomObject:backgroundColorHighlighted forKey:@"UIButton_IDNColor_backgroundColorHighlighted"];
	if(self.highlighted) // 已禁用
		self.backgroundColor = backgroundColorHighlighted;
}

- (void)setHighlighted:(BOOL)highlighted
{
	BOOL old = self.highlighted;
	[super setHighlighted:highlighted];
	BOOL new = self.highlighted;
	if(old==new)
		return;
	if(new)
	{
		UIColor* color = self.backgroundColorHighlighted;
		if(color)
		{
			[self UIButton_IDNColor_SaveBackgroundColor:self.backgroundColor];
			self.backgroundColor = color;
		}
	}
	else
	{
		UIColor* color = [self UIButton_IDNColor_savedBackgroundColor];
		if(color)
			[self UIButton_IDNColor_SaveBackgroundColor:nil];
		self.backgroundColor = color;
	}
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	[super touchesBegan:touches withEvent:event];
//	UIColor* color = self.backgroundColorPressed;
//	if(color)
//	{
//		[self UIButton_IDNColor_SaveBackgroundColor:self.backgroundColor];
//		self.backgroundColor = color;
//	}
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	[super touchesEnded:touches withEvent:event];
//	UIColor* color = [self UIButton_IDNColor_savedBackgroundColor];
//	if(color)
//	{
//		self.backgroundColor = color;
//	}
//}
//
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
//{
//	[super touchesCancelled:touches withEvent:event];
//	UIColor* color = [self UIButton_IDNColor_savedBackgroundColor];
//	if(color)
//	{
//		self.backgroundColor = color;
//	}
//}

#pragma mark - disabled color

- (UIColor*)backgroundColorDisabled
{
	return [self customObjectForKey:@"UIButton_IDNColor_backgroundColorPressed"];
}
- (void)setBackgroundColorDisabled:(UIColor *)backgroundColorDisabled
{
	[self setCustomObject:backgroundColorDisabled forKey:@"UIButton_IDNColor_backgroundColorPressed"];
	if(self.enabled==NO) // 已禁用
		self.backgroundColor = backgroundColorDisabled;
}

- (void)setEnabled:(BOOL)enabled
{
	BOOL old = self.enabled;
	[super setEnabled:enabled];
	BOOL new = self.enabled;
	if(old==new)
		return;
	if(new==NO)//disable
	{
		UIColor* color = self.backgroundColorDisabled;
		if(color)
		{
			[self UIButton_IDNColor_SaveBackgroundColor:self.backgroundColor];
			self.backgroundColor = color;
		}
	}
	else
	{
		UIColor* color = [self UIButton_IDNColor_savedBackgroundColor];
		if(color)
			[self UIButton_IDNColor_SaveBackgroundColor:nil];
		self.backgroundColor = color;
	}
}

@end
