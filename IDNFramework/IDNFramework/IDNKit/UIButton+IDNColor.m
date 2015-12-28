//
//  UIButton+IDNColor.m
//  IDNFramework
//
//  Created by mahj on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIButton+IDNColor.h"
#import "NSObject+IDNCustomObject.h"

@interface UIButtonIDNColorObserver : NSObject
@property(nonatomic,weak) UIButton* button;
@end

@implementation UIButton(IDNColor)

- (void)dealloc
{
	[self unsetBgcolorObserver];
//	NSLog(@"%s", __func__);
}

- (UIColor*)idn_originBackgroundColor
{
	return [self customObjectForKey:@"idn_originBackgroundColor"];
}
- (void)idn_setOriginBackgroundColor:(UIColor*)color
{
	[self setCustomObject:color forKey:@"idn_originBackgroundColor"];
}

#pragma mark - pressed color

- (UIColor*)backgroundColorHighlighted
{
	return [self customObjectForKey:@"UIButton_IDNColor_backgroundColorHighlighted"];
}
- (void)setBackgroundColorHighlighted:(UIColor *)backgroundColorHighlighted
{
	[self setCustomObject:backgroundColorHighlighted forKey:@"UIButton_IDNColor_backgroundColorHighlighted"];
	[self updateBgcolorObserver];
}

#pragma mark - disabled color

- (UIColor*)backgroundColorDisabled
{
	return [self customObjectForKey:@"UIButton_IDNColor_backgroundColorPressed"];
}
- (void)setBackgroundColorDisabled:(UIColor *)backgroundColorDisabled
{
	[self setCustomObject:backgroundColorDisabled forKey:@"UIButton_IDNColor_backgroundColorPressed"];
	[self updateBgcolorObserver];
}

#pragma mark -

- (void)setBgcolorObserver
{
	UIButtonIDNColorObserver* bgcolorObserver = [self customObjectForKey:@"idn_bgcolorObserver"];
	if(bgcolorObserver) //有adaptor
		return;
	
	bgcolorObserver = [UIButtonIDNColorObserver new];
	bgcolorObserver.button = self;
	[self addObserver:bgcolorObserver forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
	[self addObserver:bgcolorObserver forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
	[self addObserver:bgcolorObserver forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
	[self setCustomObject:bgcolorObserver forKey:@"idn_bgcolorObserver"];
	
	[self idn_setOriginBackgroundColor:self.backgroundColor]; //保存原来的背景颜色
}

- (void)unsetBgcolorObserver
{
	UIButtonIDNColorObserver* bgcolorObserver = [self customObjectForKey:@"idn_bgcolorObserver"];
	if(bgcolorObserver==nil) //没有adaptor
		return;
	[self setCustomObject:nil forKey:@"idn_bgcolorObserver"];
	
	UIColor* originColor = [self idn_originBackgroundColor];
	[self idn_setOriginBackgroundColor:nil];
	[self removeObserver:bgcolorObserver forKeyPath:@"backgroundColor"];
	[self removeObserver:bgcolorObserver forKeyPath:@"highlighted"];
	[self removeObserver:bgcolorObserver forKeyPath:@"enabled"];
	self.backgroundColor = originColor;
}

- (void)updateBgcolorObserver
{
	if(self.backgroundColorDisabled || self.backgroundColorHighlighted)
	{
		[self setBgcolorObserver];
		[self idn_updateBgcolor];
	}
	else
		[self unsetBgcolorObserver];
}

- (BOOL)idn_ignoreBgcolorObserver
{
	return [[self customObjectForKey:@"idn_ignoreBgcolorObserver"] boolValue];
}
- (void)idn_setIgnoreBgcolorObserver:(BOOL)ignore
{
	[self setCustomObject:@(ignore) forKey:@"idn_ignoreBgcolorObserver"];
}

- (void)idn_updateBgcolor
{
	[self idn_setIgnoreBgcolorObserver:YES];
	
	if(self.backgroundColorDisabled && self.enabled==NO)
		self.backgroundColor = self.backgroundColorDisabled;
	else if(self.backgroundColorHighlighted && self.highlighted)
		self.backgroundColor = self.backgroundColorHighlighted;
	else
		self.backgroundColor = [self idn_originBackgroundColor];

	[self idn_setIgnoreBgcolorObserver:NO];
}

@end

@implementation UIButtonIDNColorObserver
//- (void)dealloc
//{
//	NSLog(@"%s", __func__);
//}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	if([keyPath isEqualToString:@"backgroundColor"])
	{
		if([_button idn_ignoreBgcolorObserver]==NO)
		{
			UIColor* bgcolor = [change objectForKey:NSKeyValueChangeNewKey];
			[_button idn_setOriginBackgroundColor:bgcolor]; //保存原来颜色
			[_button idn_updateBgcolor];
		}
	}
	else if([keyPath isEqualToString:@"enabled"])
	{
		[_button idn_updateBgcolor];
	}
	else if([keyPath isEqualToString:@"highlighted"])
	{
		BOOL old = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
		BOOL new = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if(old!=new)
		{
			[_button idn_updateBgcolor];
		}
	}
}

@end