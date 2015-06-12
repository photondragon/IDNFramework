//
//  IDNActivityIndicator.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNActivityIndicator.h"

@interface IDNActivityIndicator ()

@end

@implementation IDNActivityIndicator
{
	CGFloat shadowWidth;
}

- (void)initializer
{
	if(_color)
		return;
	_color = [UIColor colorWithRed:21/255.0 green:138/255.0 blue:228/255.0 alpha:1];
	_lineWidth = 3.0;
	_hidesWhenStopped = YES;
	shadowWidth = 5.0;
}
- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initializer];
	}
	return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self initializer];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initializer];
	}
	return self;
}

- (void)startAnimating
{
	if(_isAnimating)
		return;
    _isAnimating = YES;
	self.hidden = NO;
	[self startRotateAnimation];
}

- (void)stopAnimating
{
    _isAnimating = NO;
    
    [self stopRotateAnimation];
	if(_hidesWhenStopped)
		self.hidden = YES;
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

- (void)setColor:(UIColor *)color
{
	_color = color;
	[self setNeedsDisplay];
}

- (void)setLineWidth:(CGFloat)lineWidth
{
	if(lineWidth<=0)
		lineWidth = 3;
	if(_lineWidth==lineWidth)
		return;
	_lineWidth = lineWidth;
	[self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
	CGSize framesize = self.bounds.size;
	
	CGPoint center = CGPointMake(framesize.width/2, framesize.height/2.0);
	CGFloat length = framesize.width < framesize.height ? framesize.width : framesize.height;
	CGFloat pixelWidth = 1.0/[UIScreen mainScreen].scale;
	CGFloat radius = (length-pixelWidth-_lineWidth)/2.0-shadowWidth;
	
	UIBezierPath* path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:0 endAngle:M_PI clockwise:YES];
	path.lineWidth = _lineWidth;
	path.lineCapStyle = kCGLineCapRound;
	[_color setStroke];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat red,green,blue,alpha;
	[_color getRed:&red green:&green blue:&blue alpha:&alpha];
	UIColor* shadowColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.7*alpha];
	CGContextSetShadowWithColor(context, CGSizeZero, 3.0, [shadowColor CGColor]);
	
	[path stroke];
}

@end
