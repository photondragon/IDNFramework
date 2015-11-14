//
//  IDNProgressView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNProgressView.h"

@interface IDNProgressView()
@property(nonatomic) BOOL rotating;
@end

@implementation IDNProgressView

- (void)initializer
{
	if(_progressTintColor)
		return;
//	self.opaque = NO;
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

- (void)setRotating:(BOOL)rotating
{
	if(_rotating==rotating)
		return;
	_rotating = rotating;
	if(_rotating)
	{
		[self startRotateAnimation];
	}
	else
	{
		[self stopRotateAnimation];
	}
}
- (void)startRotateAnimation
{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = @(0);
	animation.toValue = @(2*M_PI);
	animation.duration = 1.f;
	animation.repeatCount = INT_MAX;
	[self.layer addAnimation:animation forKey:@"AnimationIDNLoadingView"];
}

- (void)stopRotateAnimation
{
	[self.layer removeAnimationForKey:@"AnimationIDNLoadingView"];
}

#pragma mark draw functions

- (void)drawCake{
	CGSize framesize = self.frame.size;
	CGFloat pixelWidth = 1.0/[UIScreen mainScreen].scale;
	CGFloat length = framesize.width < framesize.height ? framesize.width : framesize.height;
	CGFloat radius = length/2-pixelWidth-_lineWidth/2;
	CGPoint center = CGPointMake(framesize.width/2, framesize.height/2);
	
	[_progressTintColor set];

	UIBezierPath* path = [UIBezierPath bezierPath];
	[path addArcWithCenter:center
					radius:radius
				startAngle:-M_PI_2
				  endAngle:-M_PI_2+2.0*M_PI*_progress
				 clockwise:YES];
	[path addLineToPoint:center];
	[path addLineToPoint:CGPointMake(center.x, center.y-radius)];
	[path fill];

	[path removeAllPoints];

//	CGContextRef context = UIGraphicsGetCurrentContext();
//	CGFloat red,green,blue,alpha;
//	[_progressTintColor getRed:&red green:&green blue:&blue alpha:&alpha];
//	UIColor* shadowColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.7*alpha];
//	CGContextSetShadowWithColor(context, CGSizeZero, 2.0, [shadowColor CGColor]);
	
	if(_progress<=0)
	{
		CGFloat red,green,blue,alpha;
		[_progressTintColor getRed:&red green:&green blue:&blue alpha:&alpha];
		UIColor* backCircleColor = [UIColor colorWithRed:red*0.5 green:green*0.5 blue:blue*0.5 alpha:alpha];
		[backCircleColor setStroke];
		
		[path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI*2.0 clockwise:YES];
		path.lineWidth = _lineWidth;
		[path stroke];
		[path removeAllPoints];
		
		[_progressTintColor setStroke];
		[path addArcWithCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 clockwise:YES];
		path.lineWidth = _lineWidth;
		[path stroke];
		self.rotating = YES;
	}
	else
	{
		[path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI*2 clockwise:YES];
		path.lineWidth = _lineWidth;
		[path stroke];
		self.rotating = NO;
	}
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
