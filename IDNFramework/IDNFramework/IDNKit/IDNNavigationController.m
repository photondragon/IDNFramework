//
//  IDNNavigationController.m
//  IDNFramework
//
//  Created by photondragon on 28/12/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "IDNNavigationController.h"

// 让navController.topViewController来决定手势返回是否有效
@interface IDNNavigationControllerGestureBackDelegater : NSObject
<UIGestureRecognizerDelegate>
@property(nonatomic,weak,nullable) IDNNavigationController* navController;
@end
@implementation IDNNavigationControllerGestureBackDelegater

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	UIViewController* c = _navController.topViewController;
	if(c)
	{
		if([c respondsToSelector:@selector(gestureRecognizerShouldBegin:)])
		{
			return [((id<UIGestureRecognizerDelegate>)c) gestureRecognizerShouldBegin:gestureRecognizer];
		}
	}
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	UIViewController* c = _navController.topViewController;
	if(c)
	{
		if([c respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)])
		{
			return [((id<UIGestureRecognizerDelegate>)c) gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
		}
	}
	return YES;
}

@end

@interface IDNNavigationController ()
@end

@implementation IDNNavigationController
{
	IDNNavigationControllerGestureBackDelegater* gestureBackDelegater;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self setNavigationBarHidden:YES];
	}
	return self;
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self setNavigationBarHidden:YES];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setNavigationBarHidden:YES];
	}
	return self;
}
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
	self = [super initWithRootViewController:rootViewController];
	if (self) {
		[self setNavigationBarHidden:YES];
	}
	return self;
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
	self = [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
	if (self) {
		[self setNavigationBarHidden:YES];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	gestureBackDelegater = [[IDNNavigationControllerGestureBackDelegater alloc] init];
	gestureBackDelegater.navController = self;
	self.interactivePopGestureRecognizer.delegate = gestureBackDelegater;
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
	[super setNavigationBarHidden:YES animated:NO];
}

- (BOOL)shouldAutorotate
{
	UIViewController* c = self.topViewController;
	if(c)
		return [c shouldAutorotate];
	return [super shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	UIViewController* c = self.topViewController;
	if(c)
		return [c supportedInterfaceOrientations];
	return [super supportedInterfaceOrientations];
}

@end
