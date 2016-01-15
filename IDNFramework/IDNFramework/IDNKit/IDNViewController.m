//
//  IDNViewController.m
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "IDNViewController.h"
#import "UIImage+IDNExtend.h"

// 没功能，只用个特定类名，好识别
@interface IDNViewControllerTopBarView : UIView
@end
@implementation IDNViewControllerTopBarView
@end
// 没功能，只用个特定类名，好识别
@interface IDNViewControllerContentView : UIView
@end
@implementation IDNViewControllerContentView
@end

@interface IDNViewController ()

@property(nonatomic,readonly) CGFloat topLayoutGuideLength;

@end

@implementation IDNViewController
@synthesize idn_navigationItem=_idn_navigationItem;
@synthesize idn_topBar=_idn_topBar;
@synthesize idn_statusBar=_idn_statusBar;
@synthesize idn_navigationBar=_idn_navigationBar;
@synthesize idn_contentView=_idn_contentView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.automaticallyAdjustsScrollViewInsets = NO;

	[self setupTopBar];

	if ([self.navigationController.viewControllers indexOfObject:self] > 0)
		[self addGoBackButton];

	if(_idn_contentView)
		[self.view insertSubview:_idn_contentView atIndex:0];
}

- (void)setupTopBar
{
	if(_idn_topBar)
		return;
	CGRect frame = self.view.bounds;

	frame.size.height = 64;

	_idn_topBar = [[IDNViewControllerTopBarView alloc] initWithFrame:frame];
	_idn_topBar.translatesAutoresizingMaskIntoConstraints = NO;
//	NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:_idn_topBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-20];
//	NSArray* hContraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[topbar]-0-|" options:0 metrics:nil views:@{@"topbar":_idn_topBar}];
//	NSLayoutConstraint* heightContraint = [NSLayoutConstraint constraintWithItem:_idn_topBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64];
//	[self.view addConstraint:topConstraint];
//	[self.view addConstraint:heightContraint];
//	[self.view addConstraints:hContraints];

	frame.size.height = 20;
	_idn_statusBar = [[UIView alloc] initWithFrame:frame];
	_idn_statusBar.backgroundColor = [UINavigationBar appearance].barTintColor;
	_idn_statusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_idn_topBar addSubview:_idn_statusBar];

	frame.origin.y = 20;
	frame.size.height = 44;
	_idn_navigationBar = [[UINavigationBar alloc] initWithFrame:frame];
	_idn_navigationBar.translucent = NO;
//	_idn_navigationBar.translatesAutoresizingMaskIntoConstraints = NO;
	[_idn_topBar addSubview:_idn_navigationBar];

	[self.view addSubview:_idn_topBar];

	_idn_navigationBar.items = @[self.idn_navigationItem];
}

- (UIView*)idn_topBar
{
	if(_idn_topBar==nil)
		[self setupTopBar];
	return _idn_topBar;
}
- (UIView*)idn_statusBar
{
	if(_idn_statusBar==nil)
		[self setupTopBar];
	return _idn_statusBar;
}
- (UINavigationBar*)idn_navigationBar
{
	if(_idn_navigationBar==nil)
		[self setupTopBar];
	return _idn_navigationBar;
}

- (UINavigationItem*)idn_navigationItem
{
	if(_idn_navigationItem==nil)
	{
		_idn_navigationItem = [[UINavigationItem alloc] initWithTitle:self.title];
	}
	return _idn_navigationItem;
}

- (UIView*)idn_contentView
{
	if(_idn_contentView==nil)
	{
		CGSize screensize = [UIScreen mainScreen].bounds.size;
		_idn_contentView = [[IDNViewControllerContentView alloc] initWithFrame:CGRectMake(0, 0, screensize.width, screensize.height-64)];
	}
	return _idn_contentView;
}

- (void)delGoBackButton
{
	_idn_navigationItem.leftBarButtonItems = nil;
}
- (void)addGoBackButton
{
	UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	[negativeSpacer setWidth:-16];

	UIButton* btnBack = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
	//	btnBack.backgroundColor = [UIColor redColor];
	[btnBack setImage:[UIImage commonImageGoBack] forState:UIControlStateNormal];
	[btnBack addTarget:self action:@selector(popBackViewController:) forControlEvents:UIControlEventTouchUpInside];
	UIView* backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
	[backView addSubview:btnBack]; //将btnBack放在backView中，否则会出现btnBack响应区域过大的BUG

	self.idn_navigationItem.leftBarButtonItems = @[negativeSpacer,[[UIBarButtonItem alloc] initWithCustomView:backView]];
}

- (void)popBackViewController:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)delCloseButton
{
	_idn_navigationItem.leftBarButtonItems = nil;
}
- (void)addCloseButton
{
	self.idn_navigationItem.leftBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(dismissIDNNavigationController:)]];
}

- (void)dismissIDNNavigationController:(id)sender
{
	if(self.navigationController)
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	else
		[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)hideTopBar;
{
	_idn_topBar.hidden = YES;
}

- (BOOL)isLandscape
{
	CGSize framesize = self.view.frame.size;
	return framesize.width > framesize.height;
}
- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	// TopBar布局只能用下面的代码，不能用autoresizingMask
	CGSize framesize = self.view.bounds.size;
	CGFloat navBarHeight;
	if([self isLandscape])
		navBarHeight = 32;
	else
		navBarHeight = 44;
	CGRect topBarFrame = CGRectMake(0, self.topLayoutGuide.length-20, framesize.width, 20+navBarHeight);
	_idn_topBar.frame = topBarFrame;
	_idn_navigationBar.frame = CGRectMake(0, 20, framesize.width, navBarHeight);

	if(_idn_contentView)
	{
		_idn_contentView.frame = CGRectMake(0, topBarFrame.origin.y+topBarFrame.size.height, framesize.width, framesize.height-topBarFrame.origin.y-topBarFrame.size.height);
	}
}

- (CGFloat)topLayoutGuideLength
{
	if([self isLandscape])
		return self.topLayoutGuide.length+32;
	else
		return self.topLayoutGuide.length+44;
}

- (void)bringTopBarToFront
{
	[self.view bringSubviewToFront:_idn_topBar];
}

- (void)setTitle:(NSString *)title
{
	[super setTitle:title];
	_idn_navigationItem.title = title;
}

@end
