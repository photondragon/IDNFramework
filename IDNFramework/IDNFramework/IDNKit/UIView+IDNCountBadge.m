//
//  UIView+IDNCountBadge.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIView+IDNCountBadge.h"
#import <objc/runtime.h>

//弧度转角度
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
//角度转弧度
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define countFontSize 8.0 //显示“个数”的标签的字体大小

// 显示个数的View，红底白字
@interface UIViewBadgeCountView : UIView
{
	NSString* text;
	NSDictionary* fontDictionary;
	CGFloat countBackRadius;
}
@property(nonatomic) NSInteger count;
@property(nonatomic) UIFont* font;
@property(nonatomic,strong) UIColor* textColor;
@property(nonatomic,strong) UIColor* badgeColor;

@end

@implementation UIViewBadgeCountView

- (void)initializer
{
	if(_font)
		return;
	self.userInteractionEnabled = NO;
	self.translatesAutoresizingMaskIntoConstraints = NO;
	self.backgroundColor = [UIColor clearColor];

	static UIFont* countFont = nil;
	if(countFont==nil)
		countFont = [UIFont fontWithName:@"ArialMT" size:countFontSize];
	_font = countFont;
	_textColor = [UIColor whiteColor];
	fontDictionary = @{NSFontAttributeName:_font,
					   NSForegroundColorAttributeName:_textColor};
	
	static UIColor* defaultBadgeColor = nil;
	if(defaultBadgeColor==nil)
	{
//		defaultBadgeColor = [UIColor colorWithRed:241/255.0 green:85/255.0 blue:85/255.0 alpha:1.0];
		defaultBadgeColor = [UIColor colorWithRed:27/255.0 green:159/255.0 blue:224/255.0 alpha:1.0];
	}
	_badgeColor = defaultBadgeColor;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initializer];
	}
	return self;
}

- (CGSize)intrinsicContentSize
{
	if (text.length==0) {
		return CGSizeZero;
	}
	
	if(fontDictionary==nil)
	{
		fontDictionary = @{NSFontAttributeName:_font,
						   NSForegroundColorAttributeName:_textColor};
	}
	CGSize size = [text sizeWithAttributes:fontDictionary];
	CGFloat fontSize = _font.pointSize;
	countBackRadius = fontSize-2;
	size.width = (int)(size.width+countBackRadius*2-fontSize/2.0+0.5);
	if(size.width<countBackRadius*2)
		size.width = countBackRadius*2;
	size.height = countBackRadius*2;
	return size;
}

- (void)setBadgeColor:(UIColor *)badgeColor
{
	_badgeColor = badgeColor;
	[self setNeedsDisplay];
}

- (void)setTextColor:(UIColor *)textColor
{
	_textColor = textColor;
	fontDictionary = nil;
	[self setNeedsDisplay];
}

- (void)setCount:(NSInteger)count
{
	if(_count==count)
		return;
//	if(count<0)
//		count = 0;
	_count = count;
	
	if(count==0)
	{
		text = nil;
	}
	else
	{
		if(count>999)
			text = @"999+";
		else if(count<-99)
			text = @"-99+";
		else
			text = [NSString stringWithFormat:@"%d", (int)count];
	}
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
	_font = font;
	fontDictionary = nil;
	[self invalidateIntrinsicContentSize];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	if(self.count==0)//个数为0，不显示
		return;
	NSInteger len = text.length;
	
	CGSize frameSize = self.frame.size;
	
	[_badgeColor setFill];
	
	if(fontDictionary==nil)
		fontDictionary = @{NSFontAttributeName:_font,
						   NSForegroundColorAttributeName:_textColor};
	CGSize size = [text sizeWithAttributes:fontDictionary];
	CGFloat fontSize = _font.pointSize;
	countBackRadius = fontSize-2;

	UIBezierPath* countBackPath = [UIBezierPath bezierPath];
	CGPoint center = CGPointMake(frameSize.width/2.0, frameSize.height/2.0);
	if(len>1)
	{
		CGFloat halfwidth = ((size.width-fontSize*0.75)/2.0);
		[countBackPath moveToPoint:CGPointMake(center.x-halfwidth, center.y-countBackRadius)];
		[countBackPath addLineToPoint:CGPointMake(center.x+halfwidth, center.y-countBackRadius)];
		[countBackPath addArcWithCenter:CGPointMake(center.x+halfwidth, center.y)
								 radius:countBackRadius
							 startAngle:DEGREES_TO_RADIANS(-90)
							   endAngle:DEGREES_TO_RADIANS(90)
							  clockwise:YES];
		[countBackPath addLineToPoint:CGPointMake(center.x-halfwidth, center.y+countBackRadius)];
		[countBackPath addArcWithCenter:CGPointMake(center.x-halfwidth, center.y)
								 radius:countBackRadius
							 startAngle:DEGREES_TO_RADIANS(90)
							   endAngle:DEGREES_TO_RADIANS(270)
							  clockwise:YES];
	}
	else
	{
		[countBackPath addArcWithCenter:center
								 radius:countBackRadius
							 startAngle:0
							   endAngle:DEGREES_TO_RADIANS(360.0)
							  clockwise:YES];
	}
	[countBackPath fill];
	[text drawInRect:CGRectMake(center.x-size.width/2.0, center.y-size.height/2.0, size.width, size.height) withAttributes:fontDictionary];
}

@end

static char badgeLabelKey = 0;

@implementation UIView(IDNCountBadge)

- (UIViewBadgeCountView*)badgeCountView
{
	UIViewBadgeCountView* countView = objc_getAssociatedObject(self, &badgeLabelKey);
	if(countView==nil)
	{
		countView = [[UIViewBadgeCountView alloc] init];
		[self addSubview:countView];
		
		NSLayoutConstraint* countViewCenterX = [NSLayoutConstraint constraintWithItem:countView
																			attribute:NSLayoutAttributeCenterX
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self
																			attribute:NSLayoutAttributeRight
																		   multiplier:1.0
																			 constant:-4];
		NSLayoutConstraint* countViewCenterY = [NSLayoutConstraint constraintWithItem:countView
																			attribute:NSLayoutAttributeTop
																			relatedBy:NSLayoutRelationEqual
																			   toItem:self
																			attribute:NSLayoutAttributeTop
																		   multiplier:1.0
																			 constant:0];
		[self addConstraint:countViewCenterX];
		[self addConstraint:countViewCenterY];

		objc_setAssociatedObject(self, &badgeLabelKey, countView, OBJC_ASSOCIATION_ASSIGN);
	}
	return countView;
}

- (void)setCountInBadge:(NSInteger)countInBadge
{
	[self badgeCountView].count = countInBadge;
	[self setNeedsUpdateConstraints];
	[self setNeedsLayout];
}
- (NSInteger)countInBadge
{
	UIViewBadgeCountView* countView = objc_getAssociatedObject(self, &badgeLabelKey);
	return countView.count;
}
- (UIColor*)badgeColor
{
	return [self badgeCountView].badgeColor;
}
- (void)setBadgeColor:(UIColor*)badgeColor
{
	[self badgeCountView].badgeColor = badgeColor;
}
- (UIFont*)badgeFont
{
	return [self badgeCountView].font;
}
- (void)setBadgeFont:(UIFont *)badgeFont
{
	[self badgeCountView].font = badgeFont;
}

@end
