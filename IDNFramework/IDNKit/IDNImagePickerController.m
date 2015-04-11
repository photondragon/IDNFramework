//
//  IDNImagePickerController.m
//  IDNFramework
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 ios dev net. All rights reserved.
//

#import "IDNImagePickerController.h"

@interface IDNImagePickerController ()
<UINavigationControllerDelegate,
UIImagePickerControllerDelegate>

@property(nonatomic,strong) UISegmentedControl* segmentSwitchSource;

@property(nonatomic,strong) NSMutableArray* photoSources;
@property(nonatomic,weak) id<UINavigationControllerDelegate,UIImagePickerControllerDelegate> outsideDelegate;//外部委托

@property(nonatomic,weak) UIViewController* curImagePickerViewController;

@end

@implementation IDNImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];

	//创建用于切换sourceType的UISegmentedControl控件
	UISegmentedControl* segmentSwitchSource = [[UISegmentedControl alloc] init];
	[segmentSwitchSource addTarget:self action:@selector(changeSource:) forControlEvents:UIControlEventValueChanged];
	self.segmentSwitchSource = segmentSwitchSource;

	self.photoSources = [[NSMutableArray alloc] init];

	int initSourceIndex = 0;
	int sourcesCount = 0;
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		[self.photoSources addObject:@(UIImagePickerControllerSourceTypeCamera)];
		[self.segmentSwitchSource insertSegmentWithTitle:@"相机" atIndex:sourcesCount++ animated:NO];
	}
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
	{
		initSourceIndex = sourcesCount; //首次显示相册，然后再立即切回相机
		[self.photoSources addObject:@(UIImagePickerControllerSourceTypeSavedPhotosAlbum)];
		[self.segmentSwitchSource insertSegmentWithTitle:@"相册" atIndex:sourcesCount++ animated:NO];
	}
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		[self.photoSources addObject:@(UIImagePickerControllerSourceTypePhotoLibrary)];
		[self.segmentSwitchSource insertSegmentWithTitle:@"图库" atIndex:sourcesCount++ animated:NO];
	}
	self.segmentSwitchSource.frame = CGRectMake(0, 0, 60*sourcesCount+1, 30);

	[super setDelegate:self]; //把委托设置为自己，用于在改变sourceType时设置navigationItem.titleView

	//首次显示相册，然后再立即切回相机。
	//这是为了解决iOS6下首次显示相机时，导航条默认透明（即使设置bar.translucent=NO首次显示还是透明）的BUG
	self.segmentSwitchSource.selectedSegmentIndex = initSourceIndex;
	[self changeSourceType];
	if(initSourceIndex!=0)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			self.segmentSwitchSource.selectedSegmentIndex = 0;
			[self changeSourceType];
		});
	}
}

- (void)changeSource:(id)sender
{
	[self changeSourceType];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	if(self.sourceType==UIImagePickerControllerSourceTypeCamera)
		return UIStatusBarStyleLightContent;
	else
		return UIStatusBarStyleDefault;
}

- (void)changeSourceType
{
	NSInteger index = self.segmentSwitchSource.selectedSegmentIndex;
	UIImagePickerControllerSourceType type = [self.photoSources[index] integerValue];
	self.sourceType = type;

	//设置状态栏和导航条的颜色
	if(type==UIImagePickerControllerSourceTypeCamera)
	{
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
		if([self.navigationBar respondsToSelector:@selector(setBarTintColor:)])
			[self.navigationBar setBarTintColor:[UIColor blackColor]];
		[self.segmentSwitchSource setTintColor:[UIColor whiteColor]];
		self.navigationBar.translucent = NO;
	}
	else
	{
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
		if([self.navigationBar respondsToSelector:@selector(setBarTintColor:)])
			[self.navigationBar setBarTintColor:nil];
		[self.segmentSwitchSource setTintColor:nil];
	}
}

- (void)setDelegate:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate>)delegate
{
	self.outsideDelegate = delegate;//委托消息先发给self，然后再转给outsideDelegate
}

#pragma mark delegate bridge

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
//	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];//当导航条是深色时，设置状态栏文本为白色
	if(navigationController.viewControllers.count>=2)
		return;
	
	if(viewController==nil)
	{
		self.curImagePickerViewController.navigationItem.titleView = nil;
	}
	else
	{
		//当sourceType设为相机时，默认会隐藏导航条和状态栏，这里让它们显示出来
		if(self.sourceType==UIImagePickerControllerSourceTypeCamera)
		{
			if([viewController respondsToSelector:@selector(edgesForExtendedLayout)])
				viewController.edgesForExtendedLayout = 0;
			if(self.navigationBar.hidden==YES)
			{
				[[UIApplication sharedApplication] setStatusBarHidden:NO];//这句必须在下一句之前，否则在某些情况下会出现状态栏和导航条重叠的情况
				[self setNavigationBarHidden:NO animated:NO];
			}
		}
		
		viewController.navigationItem.titleView = self.segmentSwitchSource;
	}
	self.curImagePickerViewController = viewController;
	
	if([self.outsideDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.outsideDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
}
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
	if([self.outsideDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
		[self.outsideDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
}
- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController{
	if([self.outsideDelegate respondsToSelector:@selector(navigationControllerSupportedInterfaceOrientations:)])
		return [self.outsideDelegate navigationControllerSupportedInterfaceOrientations:navigationController];
	return UIInterfaceOrientationMaskAll;
}
- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController{
	if([self.outsideDelegate respondsToSelector:@selector(navigationControllerPreferredInterfaceOrientationForPresentation:)])
		return [self.outsideDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationController];
	return UIInterfaceOrientationUnknown;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	if([self.outsideDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingMediaWithInfo:)])
		[self.outsideDelegate imagePickerController:picker didFinishPickingMediaWithInfo:info];
	else
		[picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	if([self.outsideDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)])
		[self.outsideDelegate imagePickerControllerDidCancel:picker];
	else
		[picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
