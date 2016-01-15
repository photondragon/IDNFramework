//
//  IDNScanCodeView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNTopTabController.h"

#define TabWidth 60.0

@implementation UIViewController(IDNTopTabController)

- (NSMutableDictionary*)extensionDatas
{
	static NSMutableDictionary* dicExtensionDatas = nil;
	if(dicExtensionDatas==nil)
	{
		@synchronized(self)
		{
			if(dicExtensionDatas==nil)
			{
				dicExtensionDatas = [[NSMutableDictionary alloc] init];
			}
		}
	}
	return dicExtensionDatas;
}
// 每个Controller的扩展数据用一个数组存储，第0个是leftButton或@(0)，第1个是rightButton或@(0)，第2个是[NSValue valueWithNonretainedObject:topTabController]
- (NSMutableArray*) extensionData
{
	return [self extensionDatas][[NSValue valueWithNonretainedObject:self]];
}
- (void)setExtensionData:(NSMutableArray*)data
{
	[[self extensionDatas] setObject:data forKey:[NSValue valueWithNonretainedObject:self]];
}
- (NSMutableArray*) extensionDataOrCreate
{
	NSMutableArray* data = [self extensionDatas][[NSValue valueWithNonretainedObject:self]];
	if(data==nil)
	{
		data = [NSMutableArray arrayWithObjects:@(0),@(0),[NSValue valueWithNonretainedObject:nil], nil];
		[self setExtensionData:data];
	}
	return data;
}
//- (void)removeExtensionData
//{
//	[[self extensionDatas] removeObjectForKey:[NSValue valueWithNonretainedObject:self]];
//}

- (UIBarButtonItem*)topTabBarLeftButton
{
	NSMutableArray* data = [self extensionData];
	if(data==nil)
		return nil;
	
	id obj0 = data[0];
	if([obj0 isKindOfClass:[NSNumber class]])
		return nil;
	return obj0;
}
- (void)setTopTabBarLeftButton:(UIButton*)topTabBarLeftButton
{
	NSMutableArray* data = [self extensionDataOrCreate];
	[data replaceObjectAtIndex:0 withObject:topTabBarLeftButton];
}

- (UIBarButtonItem*)topTabBarRightButton
{
	NSMutableArray* data = [self extensionData];
	if(data==nil)
		return nil;
	
	id obj1 = data[1];
	if([obj1 isKindOfClass:[NSNumber class]])
		return nil;
	return obj1;
}

- (void)setTopTabBarRightButton:(UIButton*)topTabBarLeftButton
{
	NSMutableArray* data = [self extensionDataOrCreate];
	[data replaceObjectAtIndex:1 withObject:topTabBarLeftButton];
}

- (IDNTopTabController*)topTabController
{
	NSMutableArray* data = [self extensionData];
	if(data==nil)
		return nil;
	
	NSValue* obj = data[2];
	return [obj nonretainedObjectValue];
}
- (void)setTopTabController:(IDNTopTabController *)controller
{
	NSMutableArray* data = [self extensionDataOrCreate];
	[data replaceObjectAtIndex:2 withObject:[NSValue valueWithNonretainedObject:controller]];
}

@end

// 因为barView是由NavController负责加入NavBar的，无法为其设置constraints。
// barView是通过AutoResizing来调整大小的，所以要借助这个类，在加入NavBar之前让barView加入NavigationBar时的大小与其一致。
@interface IDNTopTabBarView : UIView

@end
@implementation IDNTopTabBarView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if(newSuperview)
	{
		self.frame = newSuperview.frame;
	}
}

@end

@interface IDNTopTabController ()
{
//	NSMutableDictionary* dicPagesState;//记录子页面是否已加入视图树中，如果已加入，则(key=pageIndex，value=TabPageAdded)
//	BOOL didAppear;
}

@property (nonatomic, weak) UIView* barView; //=pagesController.navigationItem.titleView
@property (nonatomic, weak) UISegmentedControl* segment; //加入self.barView
@property (nonatomic, weak) NSLayoutConstraint* segmentWidthConstraint;
@property (nonatomic, weak) UIButton* leftBarButton; //当前正在显示的pageController带有的左按钮
@property (nonatomic, weak) UIButton* rightBarButton; //当前正在显示的pageController带有的右按钮

@end

@implementation IDNTopTabController

// tab按钮用UISegmentedControl来实现，放在self.navigationItem.titleView中
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		_selectedTabIndex = -1;

		UISegmentedControl* seg = [[UISegmentedControl alloc] init];
		seg.translatesAutoresizingMaskIntoConstraints = NO;
		[seg addTarget:self action:@selector(onTabSelected:) forControlEvents:UIControlEventValueChanged];
		
		UIView* barView = [[IDNTopTabBarView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
		barView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[barView addSubview:seg];
		
		self.navigationItem.titleView = barView;
		self.edgesForExtendedLayout = UIRectEdgeNone;
		
		// constrains: segment位于barView的中间
		NSLayoutConstraint* constraintCenterX = [NSLayoutConstraint constraintWithItem:seg
																			 attribute:NSLayoutAttributeCenterX
																			 relatedBy:NSLayoutRelationEqual
																				toItem:barView
																			 attribute:NSLayoutAttributeCenterX
																			multiplier:1
																			  constant:0];
		NSLayoutConstraint* constraintCenterY = [NSLayoutConstraint constraintWithItem:seg
																			 attribute:NSLayoutAttributeCenterY
																			 relatedBy:NSLayoutRelationEqual
																				toItem:barView
																			 attribute:NSLayoutAttributeCenterY
																			multiplier:1
																			  constant:0];
		[barView addConstraints:@[constraintCenterX, constraintCenterY]];
		
		// constraint: segment宽度和高度
		NSLayoutConstraint* constraintWidth = [NSLayoutConstraint constraintWithItem:seg
																		   attribute:NSLayoutAttributeWidth
																		   relatedBy:NSLayoutRelationEqual
																			  toItem:nil
																		   attribute:NSLayoutAttributeNotAnAttribute
																		  multiplier:1
																			constant:0];
		NSLayoutConstraint* constraintHeight = [NSLayoutConstraint constraintWithItem:seg
																			attribute:NSLayoutAttributeHeight
																			relatedBy:NSLayoutRelationEqual
																			   toItem:nil
																			attribute:NSLayoutAttributeNotAnAttribute
																		   multiplier:1
																			 constant:29];
		[seg addConstraints:@[constraintWidth, constraintHeight]];
		
		self.segmentWidthConstraint = constraintWidth;
		self.segment = seg;
		self.barView = barView;
	}
	return self;
}

- (void)updateSegmentWidth
{
	NSUInteger count = self.segment.numberOfSegments;
	
	CGFloat width;
	if(count>0)
		width = (count*(TabWidth+1))+1;
	else
		width = 0;

	self.segmentWidthConstraint.constant = width;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)setPageControllers:(NSArray *)tabControllers
{
	//先移除当前Page
	if(self.selectedTabIndex>=0)
	{
		UIViewController* controller = self.pageControllers[self.selectedTabIndex];
		[controller.view removeFromSuperview];
	}
	_selectedTabIndex = -1;
	//清理之前的Pages
	[self.leftBarButton removeFromSuperview];
	[self.rightBarButton removeFromSuperview];
	self.leftBarButton = nil;
	self.rightBarButton = nil;
	for(NSInteger i = 0; i< _segment.numberOfSegments; i++)
	{
		UIViewController* controller = self.pageControllers[i];
		[controller setTopTabController:nil];
	}
	[_segment removeAllSegments];
	
	_pageControllers = [tabControllers copy];
	NSInteger count = 0;
	for (UIViewController* controller in tabControllers)
	{
		[_segment insertSegmentWithTitle:controller.title atIndex:count animated:NO];//设置segment控件
		[controller setTopTabController:self];
		count++;
	}
	[self updateSegmentWidth];

	if (self.view.superview)//如果当前Controller已显示，则自动显示第一个Page
		self.selectedTabIndex = 0;
}

// 添加并显示指定的Page
- (void)addAndShowPageByIndex:(NSInteger)index
{
	UIView* pageView = [_pageControllers[index] view];
	pageView.translatesAutoresizingMaskIntoConstraints = NO;
	pageView.hidden = NO;
	[self.view addSubview:pageView];
	
	NSArray* constraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
																	options:0
																	metrics:0
																	  views:@{@"view":pageView}];
	NSArray* constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
																	options:0
																	metrics:0
																	  views:@{@"view":pageView}];
	
	[self.view addConstraints:constraintsH];
	[self.view addConstraints:constraintsV];
}

//添加当前Page的左右按钮
- (void)addCurrentPageBarButton
{
	if(self.selectedTabIndex==-1)
		return;
	UIViewController* pageController = _pageControllers[self.selectedTabIndex];
	UIButton* leftBarButton = pageController.topTabBarLeftButton;
	UIButton* rightBarButton = pageController.topTabBarRightButton;
	UIView* barView = self.barView;
	if(leftBarButton)
	{
		leftBarButton.translatesAutoresizingMaskIntoConstraints = NO;
		[barView addSubview:leftBarButton];
		NSLayoutConstraint* constraintCenterLeft = [NSLayoutConstraint constraintWithItem:leftBarButton
																				attribute:NSLayoutAttributeLeading
																				relatedBy:NSLayoutRelationEqual
																				   toItem:barView
																				attribute:NSLayoutAttributeLeading
																			   multiplier:1.0
																				 constant:8.0];
		NSLayoutConstraint* constraintCenterY = [NSLayoutConstraint constraintWithItem:leftBarButton
																			 attribute:NSLayoutAttributeCenterY
																			 relatedBy:NSLayoutRelationEqual
																				toItem:barView
																			 attribute:NSLayoutAttributeCenterY
																			multiplier:1.0
																			  constant:0];
		[barView addConstraints:@[constraintCenterLeft, constraintCenterY]];
		self.leftBarButton = leftBarButton;
	}
	if(rightBarButton)
	{
		rightBarButton.translatesAutoresizingMaskIntoConstraints = NO;
		[barView addSubview:rightBarButton];
		NSLayoutConstraint* constraintCenterRight = [NSLayoutConstraint constraintWithItem:rightBarButton
																				 attribute:NSLayoutAttributeTrailing
																				 relatedBy:NSLayoutRelationEqual
																					toItem:barView
																				 attribute:NSLayoutAttributeTrailing
																				multiplier:1.0
																				  constant:-8.0];
		NSLayoutConstraint* constraintCenterY = [NSLayoutConstraint constraintWithItem:rightBarButton
																			 attribute:NSLayoutAttributeCenterY
																			 relatedBy:NSLayoutRelationEqual
																				toItem:barView
																			 attribute:NSLayoutAttributeCenterY
																			multiplier:1.0
																			  constant:0];
		[barView addConstraints:@[constraintCenterRight, constraintCenterY]];
		self.rightBarButton = rightBarButton;
	}
}

// SegmentControl的选择事件
- (void)onTabSelected:(id)sender
{
	self.selectedTabIndex = self.segment.selectedSegmentIndex;
	if(self.pageControllers.count == 1)//如果只有一个Segment，则取消选中这个Segment，这样视觉效果好。
		self.segment.selectedSegmentIndex = UISegmentedControlNoSegment;//取消选中
}

- (void)setSelectedTabIndex:(NSInteger)selectedTabIndex
{
	NSInteger pagesCount = self.pageControllers.count;
	if(pagesCount==0)
		return;
	
	if(selectedTabIndex <0 || selectedTabIndex>=pagesCount)//无效选择
		return;
	
	if(_selectedTabIndex == selectedTabIndex)
		return;
	
	if(_selectedTabIndex>=0)
	{//移除之前已加载的Page
		UIViewController* prevController = _pageControllers[_selectedTabIndex];
		[prevController.view removeFromSuperview];
	}
	
	//移除之前的左右按钮
	if(self.leftBarButton)
	{
		[self.leftBarButton removeFromSuperview];
		self.leftBarButton = nil;
	}
	if(self.rightBarButton)
	{
		[self.rightBarButton removeFromSuperview];
		self.rightBarButton = nil;
	}
	
	_selectedTabIndex = selectedTabIndex;
	NSLog(@"Tab %ld selected", (long)selectedTabIndex);
	
	if(self.pageControllers.count > 1) //如果只有一个Tab，则不选中此Segment
		self.segment.selectedSegmentIndex = selectedTabIndex;
	
	[self addCurrentPageBarButton];
	
	if(selectedTabIndex>=0)//如果[TopTabController viewDidAppear:]
		[self addAndShowPageByIndex:self.selectedTabIndex];//添加并显示当前tabPage
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if(self.selectedTabIndex>=0)
	{
		UIViewController* pageController = _pageControllers[self.selectedTabIndex];
		[pageController viewWillAppear:animated];//当UIViewController Appear时，不会自动调用其子view对应的controller的*Appear方法
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if(self.selectedTabIndex>=0)
	{
		UIViewController* pageController = _pageControllers[self.selectedTabIndex];
		[pageController viewDidAppear:animated];//当UIViewController Appear时，不会自动调用其子view对应的controller的*Appear方法
	}

	if(self.selectedTabIndex==-1 && self.pageControllers.count>0)
		self.selectedTabIndex = 0;//这句只能放在DidAppear中的末尾。因为如果在WillAppear中添加，会触发[page willAppear]和[page didAppear]，然后在本函数中又再一次调用[page didAppear]，造成重复调用
}

@end
