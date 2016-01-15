//
//  UIBezierPath+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 ios dev net. All rights reserved.
//

#import "UIBezierPath+IDNExtend.h"

@implementation UIBezierPath(IDNExtend)

- (void)addPolygonWithPoints:(CGPoint*)points count:(int)count
{
	if(count<2)
		return;
	[self moveToPoint:points[0]];
	for (int i=1; i<count; i++) {
		[self addLineToPoint:points[i]];
	}
	[self closePath];
}

- (void)addRect:(CGRect)rect
{
	[self moveToPoint:rect.origin];
	[self addLineToPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y)];
	[self addLineToPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height)];
	[self addLineToPoint:CGPointMake(rect.origin.x, rect.origin.y+rect.size.height)];
	[self closePath];
}

- (void)addRoundedRect:(CGRect)rect cornorRadius:(CGFloat)cornorRadius
{
	if(cornorRadius<0)
		return;
	[self moveToPoint:CGPointMake(rect.origin.x, rect.origin.y+cornorRadius)];
	[self addArcWithCenter:CGPointMake(rect.origin.x+cornorRadius, rect.origin.y+cornorRadius) radius:cornorRadius startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
	[self addLineToPoint:CGPointMake(rect.origin.x+rect.size.width-cornorRadius, rect.origin.y)];
	[self addArcWithCenter:CGPointMake(rect.origin.x+rect.size.width-cornorRadius, rect.origin.y+cornorRadius) radius:cornorRadius startAngle:-M_PI_2 endAngle:0 clockwise:YES];
	[self addLineToPoint:CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height-cornorRadius)];
	[self addArcWithCenter:CGPointMake(rect.origin.x+rect.size.width-cornorRadius, rect.origin.y+rect.size.height-cornorRadius) radius:cornorRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
	[self addLineToPoint:CGPointMake(rect.origin.x+cornorRadius, rect.origin.y+rect.size.height)];
	[self addArcWithCenter:CGPointMake(rect.origin.x+cornorRadius, rect.origin.y+rect.size.height-cornorRadius) radius:cornorRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
	[self closePath];
}

@end
