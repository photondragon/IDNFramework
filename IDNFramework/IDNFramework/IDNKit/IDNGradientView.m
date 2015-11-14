//
//  IDNGradientView.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNGradientView.h"

@implementation IDNGradientView
{
	CGFloat _locations[256];
}

- (void)setGradientColors:(NSArray *)gradientColors locations:(CGFloat[])locations
{
	NSInteger count = gradientColors.count;
	if(count<2)
		return;
	else if(count>256)
		return;
	_gradientColors = gradientColors;
	if (locations==nil) {
		CGFloat delta = 1.0/(count-1);
		for (int i=0;i<count;i++) {
			_locations[i] = i*delta;
		}
	}
	else
	{
		for(int i = 0;i<count;i++)
		{
			_locations[i] = locations[i];
		}
	}
	[self setNeedsDisplay];
}

- (void)setGradientColors:(NSArray *)gradientColors
{
	_gradientColors = gradientColors;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	if(_gradientColors.count<2)
		return;
	CGContextRef context = UIGraphicsGetCurrentContext();
	drawLinearGradient(context, self.bounds, _gradientColors, _locations);
}

void drawLinearGradient(CGContextRef context, CGRect rect, NSArray*colors, CGFloat locations[])
{
	NSInteger count = colors.count;
	if(count<2)
		return;
	else if(count>256)
		return;
	CGContextSaveGState(context);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//	NSArray *array = @[(__bridge id)startColor, (__bridge id)endColor];
	NSMutableArray* cgcolors = [NSMutableArray array];
	for (UIColor* color in colors) {
		[cgcolors addObject:(__bridge id)color.CGColor];
	}
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)cgcolors, locations); //(CGFloat[]){0.0, 1.0}
	
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	CGContextAddRect(context, rect);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	
	CGColorSpaceRelease(colorSpace);
	CGGradientRelease(gradient);
	CGContextRestoreGState(context);
}

@end
