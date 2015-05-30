//
//  IDNSplitMainController.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNSplitMainController.h"

@interface IDNSplitMainController ()

@property(nonatomic,strong,readonly) UIPanGestureRecognizer* panGestureRecognizer; //控制菜单显示的手势

@end

@implementation IDNSplitMainController
{
	UIControl* maskView; //当显示SideView时，用于盖在MainView之上，防止点击到MainView中的元素。
	UIView* snapshotTitleContainer;
	UIView* snapshotBodyContainer;
	UINavigationController* _mainController;
}

- (void)initializer
{
	if(_mainController)
		return;
	CGSize size = self.view.frame.size;
	_menuBottomMargin = 50;
	
	_mainController = [[UINavigationController alloc] init];
	_mainController.navigationBar.translucent = NO;
	_mainController.view.frame = CGRectMake(0, 0, size.width, size.height);
	_mainController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:_mainController.view];
	
	maskView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	maskView.userInteractionEnabled = YES;
	maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	maskView.hidden = YES;
	[self.view addSubview:maskView];
	UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMaskView:)];
	[maskView addGestureRecognizer:tapGesture];

	snapshotTitleContainer = [[UIView alloc] init];
	snapshotTitleContainer.backgroundColor = [UIColor orangeColor];
	snapshotTitleContainer.clipsToBounds = YES;
	snapshotTitleContainer.userInteractionEnabled = NO;
	snapshotTitleContainer.hidden = YES;
	[self.view addSubview:snapshotTitleContainer];

	snapshotBodyContainer = [[UIView alloc] init];
	snapshotBodyContainer.backgroundColor = [UIColor orangeColor];
	snapshotBodyContainer.clipsToBounds = YES;
	snapshotBodyContainer.userInteractionEnabled = NO;
	snapshotBodyContainer.hidden = YES;
	[self.view addSubview:snapshotBodyContainer];
}

//- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//	if (self) {
//		[self initializer];
//	}
//	return self;
//}
//- (instancetype)initWithCoder:(NSCoder *)aDecoder
//{
//	self = [super initWithCoder:aDecoder];
//	if (self) {
//		[self initializer];
//	}
//	return self;
//}

- (void)loadView
{
	[super loadView];
	[self initializer];
}

- (UINavigationController*)mainController
{
	if(_mainController==nil)
		[self view];
	return _mainController;
}

- (void)setMenuBottomMargin:(CGFloat)menuBottomMargin
{
	if(menuBottomMargin<20)
		menuBottomMargin = 20;
	[self view];
	if(_menuBottomMargin==menuBottomMargin)
		return;
	_menuBottomMargin = menuBottomMargin;
}

- (void)setMenuController:(UIViewController *)menuController
{
	if(_menuController==menuController)
		return;
	[self view];
	[_menuController.view removeFromSuperview];
	_menuController = menuController;
	[self addSideView];
}

- (void)addSideView
{
	if(_menuController)
	{
		if(_menuController.view.superview)//已经添加
			return;
		CGRect rect = self.view.bounds;
		rect.size.height -= _menuBottomMargin;
		_menuController.view.frame = rect;
		_menuController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_menuController.view.hidden = YES;
		[self.view insertSubview:_menuController.view aboveSubview:maskView];
	}
}

- (UIResponder*)findFirstResponderInView:(UIView*)view
{
	if (view.isFirstResponder) {
		return view;
	}
	for (UIView *subView in view.subviews) {
		UIResponder* responder = [self findFirstResponderInView:subView];
		if (responder)
			return responder;
	}
	return nil;
}

- (void)showMenuController:(BOOL)showMenu
{
	if(showMenu)
	{
		[[self findFirstResponderInView:self.view] resignFirstResponder];//取消输入焦点
		[[self findFirstResponderInView:self.view] resignFirstResponder];//再一次调用是因为在上一次resignFirstResponder中有可能会调用另一个对象的becomeFirstResponder方法，导致键盘不消失，这可能是一个BUG
	}
	[self showMenuController:showMenu animated:YES];

}

- (void)resnapshotMainController
{
	for(UIView* view in snapshotTitleContainer.subviews)
		[view removeFromSuperview];
	for(UIView* view in snapshotBodyContainer.subviews)
		[view removeFromSuperview];
	
	CGRect titleRect = _mainController.navigationBar.frame;
	CGFloat titleHeight = titleRect.origin.y + titleRect.size.height;
	
	[snapshotTitleContainer addSubview:[_mainController.view snapshotViewAfterScreenUpdates:NO]];

	UIView* snapshotView = [_mainController.view snapshotViewAfterScreenUpdates:NO];
	CGRect rect = snapshotView.frame;
	rect.origin.y = -titleHeight;
	snapshotView.frame = rect;
	[snapshotBodyContainer addSubview:snapshotView];
}

- (void)showMenuController:(BOOL)showMenu animated:(BOOL)animated
{
	if(_isShowingMenuController==showMenu)
		return;
	_isShowingMenuController = showMenu;

	if(showMenu)
	{
		[self resnapshotMainController];
		
		CGSize size = self.view.bounds.size;
		
		CGRect titleRect = _mainController.navigationBar.frame;
		CGFloat titleHeight = titleRect.origin.y + titleRect.size.height;
		titleRect = CGRectMake(0, 0, size.width, titleHeight);
		
		snapshotTitleContainer.frame = titleRect;
		snapshotTitleContainer.hidden = NO;
		
		CGRect bodyRect = CGRectMake(0, titleHeight, size.width, size.height-titleHeight);
		snapshotBodyContainer.frame = bodyRect;
		snapshotBodyContainer.hidden = NO;
		
		titleRect.origin.y -= titleHeight;
		bodyRect.origin.y += (bodyRect.size.height-_menuBottomMargin);
		if(animated)
		{
			[UIView animateWithDuration:0.5 animations:^{
				snapshotTitleContainer.frame = titleRect;
				snapshotBodyContainer.frame = bodyRect;
			}];
		}
		else
		{
			snapshotTitleContainer.frame = titleRect;
			snapshotBodyContainer.frame = bodyRect;
		}
		
		_menuController.view.hidden = NO;
		maskView.hidden = NO;
	}
	else
	{
		[self hideMenuAnimated:animated];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001), dispatch_get_main_queue(), ^{
			[self resnapshotMainController];
		});
	}
}

- (void)hideMenuAnimated:(BOOL)animated
{
	CGSize size = self.view.bounds.size;
	CGRect titleRect = _mainController.navigationBar.frame;
	CGFloat titleHeight = titleRect.origin.y + titleRect.size.height;
	titleRect = CGRectMake(0, -titleHeight, size.width, titleHeight);
	
	snapshotTitleContainer.frame = titleRect;
	snapshotTitleContainer.hidden = NO;
	
	CGRect bodyRect = CGRectMake(0, size.height-_menuBottomMargin, size.width, size.height-titleHeight);
	snapshotBodyContainer.frame = bodyRect;
	snapshotBodyContainer.hidden = NO;
	
	titleRect.origin.y = 0;
	bodyRect.origin.y = titleHeight;
	[UIView animateWithDuration:0.5 animations:^{
		snapshotTitleContainer.frame = titleRect;
		
		CGRect bodyRect = snapshotBodyContainer.frame;
		bodyRect.origin.y = titleRect.size.height;
		snapshotBodyContainer.frame = bodyRect;
	} completion:^(BOOL finished) {
		_menuController.view.hidden = YES;
		maskView.hidden = YES;
		for(UIView* view in snapshotTitleContainer.subviews)
			[view removeFromSuperview];
		for(UIView* view in snapshotBodyContainer.subviews)
			[view removeFromSuperview];
		snapshotTitleContainer.hidden = YES;
		snapshotBodyContainer.hidden = YES;
	}];
}

- (void)tapOnMaskView:(UITapGestureRecognizer*)tapGesture
{
	_isShowingMenuController = NO;
	[self hideMenuAnimated:YES];
}

@end
