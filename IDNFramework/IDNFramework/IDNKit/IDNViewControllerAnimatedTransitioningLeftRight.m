//
//  IDNViewControllerAnimatedTransitioningLeftRight.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNViewControllerAnimatedTransitioningLeftRight.h"

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
	if(self.reverse)//向左弹出
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
		
		finalFrame = CGRectOffset(initFrame, -screenBounds.size.width, 0);
		
	}
	else//从左弹入
	{
		controller = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
		finalFrame = [transitionContext finalFrameForViewController:controller];
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
