//
//  UIView+IDNKeyboard.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIView+IDNKeyboard.h"
#import <objc/runtime.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/message.h>

#pragma mark - UIView_IDNKeyboard_TapGestureShadowRecognizer
// 这个手势永远不会进入Ended/Recognied状态，但是如果检测到Tap手势，会调用[tapTarget tapSelector];
// 因为UITableView检测Tap手势时会检测是否有其它手势recognized，如果有，则UITableView的Tap手势不会生效，这会导致cell无法被选中。所以需要一个永远不会Recognized的Tap手势
@interface UIView_IDNKeyboard_TapGestureShadowRecognizer : UITapGestureRecognizer

- (void)setTapTarget:(id)tapTarget tapSelector:(SEL)tapSelector;

@end
#define TapTimeLimit 0.3

@implementation UIView_IDNKeyboard_TapGestureShadowRecognizer
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

#pragma mark - UIViewIDNKeyboardTapDelegator

@interface UIViewIDNKeyboardTapDelegator : NSObject
@property(nonatomic,weak) UIView* tapView;
- (void)tap:(UITapGestureRecognizer*)tap;
@end
@implementation UIViewIDNKeyboardTapDelegator

- (void)tap:(UIView_IDNKeyboard_TapGestureShadowRecognizer*)tap
{
	UIView* tapView = self.tapView;
	if(tapView==nil)
		return;
	UIView* hitView = [tapView hitTest:[tap locationInView:tapView] withEvent:nil];
	if([hitView canBecomeFirstResponder])
		return;
	else if([hitView isKindOfClass:[UIButton class]]) //如果点到了按钮
	{
		if(((UIButton*)hitView).enabled) //并且按钮可点
			return;
	}

	// 点到其它区域则resignFirstResponder
	[tapView endEditing:YES];
}

@end

#pragma mark - UIView(IDNKeyboard)

@implementation UIView(IDNKeyboard)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfUIViewIDNKeyboardBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil || dic[@"block"]==nil)
		return;
	if(newWindow)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	}
}

- (void (^)(CGFloat bottomDistance, double animationDuration, UIViewAnimationCurve animationCurve))keyboardFrameWillChangeBlock
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	return dic[@"block"];
}

- (void)setKeyboardFrameWillChangeBlock:(void (^)(CGFloat bottomDistance, double animationDuration, UIViewAnimationCurve animationCurve))keyboardFrameWillChangeBlock
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	if(keyboardFrameWillChangeBlock)
	{
		if(dic[@"block"]==nil && self.window)//之前没有设置Block而self已经在视图树中显示
		{
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
		}
		dic[@"block"] = keyboardFrameWillChangeBlock;
	}
	else
	{
		if(dic[@"block"] && self.window)//已经设置Block而且self已经在视图树中显示
			[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
		[dic removeObjectForKey:@"block"];
	}
}

- (void)viewKeyboardWillChangeFrame:(NSNotification*)note
{
	NSDictionary *userInfo = [note userInfo];
	
	NSTimeInterval animationDuration;
	NSNumber *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	animationDuration = [animationDurationValue doubleValue];
	//	[animationDurationValue getValue:&animationDuration];
	NSNumber *animationCurveValue = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	UIViewAnimationCurve animationCurve = [animationCurveValue integerValue];
	
	NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [self convertRect:[aValue CGRectValue] fromView:nil];//获取键盘坐标，并由屏幕坐标转为view的坐标
	CGRect containerRect = self.bounds;
	CGFloat bottomDistance = containerRect.size.height - keyboardRect.origin.y;
	
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	if(dic[@"block"])
	{
		void (^keyboardFrameWillChangeBlock)(CGFloat,double,UIViewAnimationCurve) = dic[@"block"];
		keyboardFrameWillChangeBlock(bottomDistance,animationDuration,animationCurve);
	}
}

- (BOOL)autoResignFirstResponder
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	return [dic[@"autoResign"] boolValue];
}

- (void)setAutoResignFirstResponder:(BOOL)autoResignFirstResponder
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNKeyboardBindData];
	dic[@"autoResign"] = @(autoResignFirstResponder);
	if(autoResignFirstResponder)
	{
		UIViewIDNKeyboardTapDelegator* tapDelegator = [UIViewIDNKeyboardTapDelegator new];
		tapDelegator.tapView = self;
		UIView_IDNKeyboard_TapGestureShadowRecognizer* tap = [[UIView_IDNKeyboard_TapGestureShadowRecognizer alloc] init];
		[tap setTapTarget:tapDelegator tapSelector:@selector(tap:)];
//		tap.delaysTouchesBegan = NO;
//		tap.delaysTouchesEnded = NO;
		[self addGestureRecognizer:tap];
		dic[@"tapDelegator"] = tapDelegator;
		dic[@"tap"] = tap;
	}
	else
	{
		UITapGestureRecognizer* tap = dic[@"tap"];
		[self removeGestureRecognizer:tap];
		[dic removeObjectForKey:@"tapDelegator"];
		[dic removeObjectForKey:@"tap"];
	}
}

@end

