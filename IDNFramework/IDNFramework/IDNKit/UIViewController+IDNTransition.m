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
@end

@implementation IDNViewControllerTransitionDelegator

#pragma mark UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{//弹出商品详情时使用
	IDNViewControllerAnimatedTransitioningLeftRight* t = [[IDNViewControllerAnimatedTransitioningLeftRight alloc] init];
	return t;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
	IDNViewControllerAnimatedTransitioningLeftRight* t = [[IDNViewControllerAnimatedTransitioningLeftRight alloc] init];
	t.reverse = YES;
	return t;
}

@end

static char transitionDelegatorKey = 0;

@implementation UIViewController(IDNTransition)

- (void)presentViewControllerFromLeft:(UIViewController *)viewController completion:(void (^)(void))completion
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
		objc_setAssociatedObject(viewController, &transitionDelegatorKey, transitionDelegator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	viewController.transitioningDelegate = transitionDelegator;
	
	[self presentViewController:viewController animated:YES completion:^{
		if(completion)
			completion();
	}];
}

@end
