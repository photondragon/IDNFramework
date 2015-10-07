//
//  IDNTapGestureRecognizer.m
//  xiangyue
//
//  Created by mahj on 15/7/23.
//  Copyright (c) 2015年 shendou. All rights reserved.
//

#import "IDNTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/message.h>

#define TapTimeLimit 0.3

@implementation IDNTapGestureRecognizer
{
	CGPoint touchBeganPoint;
	NSTimeInterval touchBeganTime;
	__weak UITouch* firstTouch;
	id tapTarget;
	SEL tapSelector;
}

- (void)reset
{
	firstTouch = nil;
}

- (BOOL)shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	
	if(touches.count>1)
	{
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	if(firstTouch)//已经有一个touch，现在这个是第二个
	{
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	firstTouch = [touches anyObject];
	touchBeganPoint = [firstTouch locationInView:self.view];
	touchBeganTime = [NSDate timeIntervalSinceReferenceDate];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	
	UITouch* touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
	if ((point.x-touchBeganPoint.x)*(point.x-touchBeganPoint.x)+
		(point.y-touchBeganPoint.y)*(point.y-touchBeganPoint.y) > 100.0) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	if(time-touchBeganTime>TapTimeLimit)
	{
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//	[super touchesEnded:touches withEvent:event];
	
	UITouch* touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
	if ((point.x-touchBeganPoint.x)*(point.x-touchBeganPoint.x)+
		(point.y-touchBeganPoint.y)*(point.y-touchBeganPoint.y) > 100.0) {
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	if(time-touchBeganTime>TapTimeLimit)
	{
		self.state = UIGestureRecognizerStateFailed;
		return;
	}
	self.state = UIGestureRecognizerStateFailed;
	((void (*)(id, SEL, id))objc_msgSend)(tapTarget, tapSelector, self);
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	
	self.state = UIGestureRecognizerStateCancelled;
}

- (void)setTapTarget:(id)target tapSelector:(SEL)selector
{
	tapTarget = target;
	tapSelector = selector;
}

@end
