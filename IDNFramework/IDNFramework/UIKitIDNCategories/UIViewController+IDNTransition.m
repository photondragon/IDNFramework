//
//  UIViewController+IDNTransition.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIViewController+IDNTransition.h"
#import <objc/runtime.h>

//从左弹入，向左弹出；或者从右弹入，向右弹出
@interface IDNViewControllerAnimatedTransitioningLeftRight : NSObject
<UIViewControllerAnimatedTransitioning>

@property(nonatomic) BOOL right; //为NO表示从左进，向左出；YES表示从右进，向右出
@property(nonatomic) BOOL reverse; //默认NO，表示从左弹入；为YES表示向左弹出

@end

@implementation IDNViewControllerAnimatedTransitioningLeftRight

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
	return 0.3f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	UIViewController *controller;
	CGRect finalFrame;
	if(_reverse)//向左弹出
	{
		//新view controller
		UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
		toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
		[[transitionContext containerView] addSubview:toVC.view];

		//旧view controller
		controller = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
		CGRect initFrame = [transitionContext initialFrameForViewController:controller];
		controller.view.frame = initFrame;
		[[transitionContext containerView] addSubview:controller.view];

		if(_right)
			finalFrame = CGRectOffset(initFrame, screenBounds.size.width, 0);
		else
			finalFrame = CGRectOffset(initFrame, -screenBounds.size.width, 0);

	}
	else//从左弹入
	{
		controller = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
		finalFrame = [transitionContext finalFrameForViewController:controller];
		if(_right)
			controller.view.frame = CGRectOffset(finalFrame, screenBounds.size.width, 0);
		else
			controller.view.frame = CGRectOffset(finalFrame, -screenBounds.size.width, 0);
		[[transitionContext containerView] addSubview:controller.view];
	}

	[UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
		controller.view.frame = finalFrame;
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:YES];
	}];
}

@end

#pragma mark -

@interface IDNViewControllerTransitionDelegator : NSObject
<UIViewControllerTransitioningDelegate>
@property(nonatomic) BOOL fromRight;
@end

@implementation IDNViewControllerTransitionDelegator

#pragma mark UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{//弹出商品详情时使用
	IDNViewControllerAnimatedTransitioningLeftRight* t = [[IDNViewControllerAnimatedTransitioningLeftRight alloc] init];
	t.right = _fromRight;
	return t;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	IDNViewControllerAnimatedTransitioningLeftRight* t = [[IDNViewControllerAnimatedTransitioningLeftRight alloc] init];
	t.right = _fromRight;
	t.reverse = YES;
	return t;
}

@end

static char transitionDelegatorKey = 0;

@implementation UIViewController(IDNTransition)

- (void)presentViewControllerFromLeft:(UIViewController *)viewController completion:(void (^)(void))completion
{
	[self presentViewController:viewController fromRight:NO completion:completion];
}
- (void)presentViewControllerFromRight:(UIViewController *)viewController completion:(void (^)(void))completion
{
	[self presentViewController:viewController fromRight:YES completion:completion];
}
- (void)presentViewController:(UIViewController *)viewController fromRight:(BOOL)fromRight completion:(void (^)(void))completion
{
	IDNViewControllerTransitionDelegator* transitionDelegator = objc_getAssociatedObject(viewController, &transitionDelegatorKey);
	if(viewController.transitioningDelegate &&
	   transitionDelegator &&
	   viewController.transitioningDelegate != transitionDelegator)
	{
		NSLog(@"无法presentViewController:%@", viewController);
		return;
	}
	
	if(transitionDelegator==nil)
	{
		transitionDelegator = [[IDNViewControllerTransitionDelegator alloc] init];
		transitionDelegator.fromRight = fromRight;
		objc_setAssociatedObject(viewController, &transitionDelegatorKey, transitionDelegator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	viewController.transitioningDelegate = transitionDelegator;
	
	[self presentViewController:viewController animated:YES completion:^{
		if(completion)
			completion();
	}];
}

@end
