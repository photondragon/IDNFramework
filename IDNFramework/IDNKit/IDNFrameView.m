//
//  IDNFrameView.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNFrameView.h"

@implementation IDNFrameView

- (void)initializer
{
	if(_frameColor)
		return;
	_drawEdgeLines = 0;
	_frameColor = [UIColor colorWithWhite:0.85 alpha:1.0];
	_frameLineWidth = 1.0/[UIScreen mainScreen].scale;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initializer];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initializer];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initializer];
	}
	return self;
}

- (void)setDrawEdgeLines:(DrawEdgeLine)drawEdgeLines
{
	if(_drawEdgeLines==drawEdgeLines)
		return;
	_drawEdgeLines = drawEdgeLines;
	[self setNeedsDisplay];
}

- (void)setFrameColor:(UIColor *)frameColor
{
	_frameColor = frameColor;
	[self setNeedsDisplay];
}

- (void)setFrameLineWidth:(CGFloat)frameLineWidth
{
	_frameLineWidth = frameLineWidth;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	if(_drawEdgeLines==0)
		return;
	CGSize framesize = self.bounds.size;
	CGFloat lineDelta = _frameLineWidth/2.0;
	
	UIBezierPath* path = [UIBezierPath bezierPath];
	
	if(_drawEdgeLines & DrawEdgeLineTop)
	{
		[path moveToPoint:CGPointMake(0, 0+lineDelta)];
		[path addLineToPoint:CGPointMake(framesize.width, +lineDelta)];
	}
	if(_drawEdgeLines & DrawEdgeLineRight)
	{
		[path moveToPoint:CGPointMake(framesize.width-lineDelta, 0)];
		[path addLineToPoint:CGPointMake(framesize.width-lineDelta, framesize.height)];
	}
	if(_drawEdgeLines & DrawEdgeLineBottom)
	{
		[path moveToPoint:CGPointMake(framesize.width, framesize.height-lineDelta)];
		[path addLineToPoint:CGPointMake(0, framesize.height-lineDelta)];
	}
	if(_drawEdgeLines & DrawEdgeLineLeft)
	{
		[path moveToPoint:CGPointMake(0+lineDelta, framesize.height)];
		[path addLineToPoint:CGPointMake(0+lineDelta, 0)];
	}
	
	[_frameColor setStroke];
	path.lineWidth = _frameLineWidth;
	[path stroke];
}

@end
