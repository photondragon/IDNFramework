//
//  IDNProgressView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNProgressView.h"

@implementation IDNProgressView

- (void)initializer
{
	if(_progressTintColor)
		return;
	_progressViewStyle = IDNProgressViewStyleDefault;
	_progressTintColor = [UIColor colorWithRed:21/255.0 green:138/255.0 blue:228/255.0 alpha:1];
	_progress = 0;
	_lineWidth = 1.0;
}

- (instancetype)init
{
	self = [super init];
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
- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initializer];
	}
	return self;
}
- (instancetype)initWithProgressViewStyle:(IDNProgressViewStyle)style
{
	self = [super init];
	if (self) {
		[self initializer];
		self.progressViewStyle = style;
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)setProgressViewStyle:(IDNProgressViewStyle)progressViewStyle
{
	if(_progressViewStyle==progressViewStyle)
		return;
	_progressViewStyle = progressViewStyle;
	[self setNeedsDisplay];
}

- (void)setProgress:(float)progress
{
	if(progress<0)
		progress = 0;
	else if(progress>1.0)
		progress = 1.0;
	if(_progress == progress)
		return;
	_progress = progress;
	[self setNeedsDisplay];
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
	_progressTintColor = progressTintColor;
	[self setNeedsDisplay];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
	_trackTintColor = trackTintColor;
	[self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
	if(lineWidth<0)
		lineWidth = 0;
	if(_lineWidth==lineWidth)
		return;
	_lineWidth = lineWidth;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	switch (_progressViewStyle) {
		case IDNProgressViewStyleCircle:
			[self drawCircle];
			break;
		case IDNProgressViewStyleCake:
		default:
			[self drawCake];
			break;
	}
}

#pragma mark draw functions

- (void)drawCake{
	CGSize framesize = self.frame.size;
	CGFloat pixelWidth = 1.0/[UIScreen mainScreen].scale;
	CGFloat length = framesize.width < framesize.height ? framesize.width : framesize.height;
	CGFloat radius = length/2-pixelWidth-_lineWidth/2;
	CGPoint center = CGPointMake(framesize.width/2, framesize.height/2);
	
	UIBezierPath* path = [UIBezierPath bezierPath];
	[path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI*2 clockwise:YES];
	
	path.lineWidth = _lineWidth;
	[_progressTintColor setStroke];
	[path stroke];
	
	[path removeAllPoints];
	
	[path addArcWithCenter:center
					radius:radius
				startAngle:-M_PI_2
				  endAngle:-M_PI_2+2.0*M_PI*_progress
				 clockwise:YES];
	[path addLineToPoint:center];
	[path addLineToPoint:CGPointMake(center.x, center.y-radius)];
	[_progressTintColor setFill];
	[path fill];
}

- (void)drawCircle{
	CGSize framesize = self.frame.size;
	CGFloat pixelWidth = 1.0/[UIScreen mainScreen].scale;
	CGFloat length = framesize.width < framesize.height ? framesize.width : framesize.height;
	CGFloat radius = length/2-pixelWidth-_lineWidth/2;
	CGPoint center = CGPointMake(framesize.width/2, framesize.height/2);
	
	UIBezierPath* path = [UIBezierPath bezierPath];
	path.lineWidth = _lineWidth;

	[path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI*2 clockwise:YES];
	[_trackTintColor setStroke];
	[path stroke];
	
	[path removeAllPoints];
	
	[path addArcWithCenter:center
					radius:radius
				startAngle:-M_PI_2
				  endAngle:-M_PI_2+2.0*M_PI*_progress
				 clockwise:YES];
	[_progressTintColor setStroke];
	[path stroke];
}

@end
