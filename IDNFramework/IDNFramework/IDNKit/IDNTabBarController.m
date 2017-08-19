//
//  IDNTabBarController.m
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "IDNTabBarController.h"

@interface IDNTabBarController ()
<UITabBarDelegate>

@end

@implementation IDNTabBarController

static IDNTabBarController* sharedTabBarController = nil;
+ (instancetype)sharedTabBarController
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedTabBarController = [[self alloc] init];
	});
	return sharedTabBarController;
}
+ (instancetype)recreateTabBarController
{
	sharedTabBarController = nil;
	sharedTabBarController = [[self alloc] init];
	return sharedTabBarController;
}

- (void)initializer
{
	if(_tabBar)
		return;
	
	CGRect frame = [UIScreen mainScreen].bounds;
	frame.origin.y = frame.size.height - 49;
	frame.size.height = 49;
	
	_tabBar = [[UITabBar alloc] initWithFrame:frame];
	_tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	
	_tabBar.delegate = self;
	
	_selectedIndex = NSNotFound;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initializer];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initializer];
	}
	return self;
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self initializer];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if(_selectedIndex!=NSNotFound)
	{
		CGSize framesize = self.view.frame.size;

		//ios7.x
		if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
		{
			CGFloat f = framesize.width;
			framesize.width = framesize.height;
			framesize.height = f;
		}
		UIViewController* c = _viewControllers[_selectedIndex];
		c.view.frame = CGRectMake(0, 0, framesize.width, framesize.height);
	}
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers
{
	if(_tabBar.superview)
		[_tabBar removeFromSuperview];
	_tabBar.items = nil;
	
	if(_selectedIndex!=NSNotFound)
	{
		UIViewController* c = _viewControllers[_selectedIndex];
		[c.view removeFromSuperview];
	}
	_selectedIndex = NSNotFound;
	
	_viewControllers = [viewControllers copy];
	
	if(_viewControllers.count)
	{
		NSMutableArray* items = [NSMutableArray new];
		for (UIViewController* c in _viewControllers) {
			[items addObject:c.tabBarItem];
		}
		
		_tabBar.items = items;
		
		_tabBar.selectedItem = items[0];
		self.selectedIndex = 0;
	}
	else
	{
		[self setNeedsStatusBarAppearanceUpdate];
	}
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
	if(_selectedIndex==selectedIndex)
		return;
	if(_selectedIndex!=NSNotFound)
	{
		UIViewController* c = _viewControllers[_selectedIndex];
		[c.view removeFromSuperview];
	}
	
	_selectedIndex = selectedIndex;
	
	[self setNeedsStatusBarAppearanceUpdate];
	
	if(_selectedIndex!=NSNotFound)
	{
		_tabBar.selectedItem = _tabBar.items[_selectedIndex];
		UIViewController* c = _viewControllers[_selectedIndex];
		[self.view addSubview:c.view];
		[c.view setNeedsLayout];
		if([c isKindOfClass:[UINavigationController class]] &&
		   [(UINavigationController*)c viewControllers].count)
			[self showTabBarInController:[(UINavigationController*)c viewControllers][0]];
		else
			[self showTabBarInController:c];
	}
}

- (UIViewController *)selectedViewController
{
	if(_selectedIndex==NSNotFound)
		return nil;
	return _viewControllers[_selectedIndex];
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController
{
	if(_viewControllers==nil)
		return;
	NSUInteger i = [_viewControllers indexOfObjectIdenticalTo:selectedViewController];
	if(i == NSNotFound)
		return;
		
	self.selectedIndex = i;
}

- (void)showTabBarInController:(nonnull UIViewController*)controller
{
	if(controller==nil)
		return;
	if(_tabBar.superview)
	{
		if(_tabBar.superview == controller.view)
			return;
		[_tabBar removeFromSuperview];
	}
	
	CGRect frame = controller.view.bounds;
	frame.origin.y = frame.size.height - 49;
	frame.size.height = 49;
	_tabBar.frame = frame;
	[controller.view addSubview:_tabBar];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	NSUInteger i = [_tabBar.items indexOfObjectIdenticalTo:item];
	self.selectedIndex = i;
}

- (BOOL)shouldAutorotate
{
	UIViewController* c = self.selectedViewController;
	if(c)
		return [c shouldAutorotate];
	return [super shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	UIViewController* c = self.selectedViewController;
	if(c)
		return [c supportedInterfaceOrientations];
	return [super supportedInterfaceOrientations];
}

- (UIViewController*)childViewControllerForStatusBarStyle
{
	if(_selectedIndex!=NSNotFound)
		return _viewControllers[_selectedIndex];
	return nil;
}

- (UIViewController*)childViewControllerForStatusBarHidden
{
	if(_selectedIndex!=NSNotFound)
		return _viewControllers[_selectedIndex];
	return nil;
}

@end
