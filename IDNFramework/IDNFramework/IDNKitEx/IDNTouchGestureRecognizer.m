//
//  IDNTouchGestureRecognizer.m
//  IDNFramework
//
//  Created by photondragon on 15/11/14.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNTouchGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation IDNTouchGestureRecognizer
{
	NSMutableSet* allTouches;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		allTouches = [NSMutableSet new];
	}
	return self;
}
- (instancetype)initWithTarget:(id)target action:(SEL)action
{
	self = [super initWithTarget:target action:action];
	if (self) {
		allTouches = [NSMutableSet new];
	}
	return self;
}
- (void)reset
{
	[allTouches removeAllObjects];
}
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
	return NO;
}
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
	return YES;
}
- (BOOL)shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	return NO;
}
- (BOOL)shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return NO;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[allTouches unionSet:touches];
	self.state = UIGestureRecognizerStateBegan;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[allTouches minusSet:touches];
	if(allTouches.count==0)
		self.state = UIGestureRecognizerStateEnded;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[allTouches minusSet:touches];
	if(allTouches.count==0)
		self.state = UIGestureRecognizerStateEnded;
}

@end
