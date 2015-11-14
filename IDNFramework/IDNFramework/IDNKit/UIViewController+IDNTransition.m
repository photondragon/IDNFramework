//
//  UIViewController+IDNTransition.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIViewController+IDNTransition.h"
#import "IDNViewControllerAnimatedTransitioningLeftRight.h"
#import <objc/runtime.h>

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
