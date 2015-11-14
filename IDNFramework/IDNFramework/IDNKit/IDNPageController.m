//
//  IDNPageController.m
//  IDNPageController
//
//  Created by photondragon on 15/7/4.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNPageController.h"
#import <objc/runtime.h>

#define MinSwipeVelocity 1024.0
#define DefaultFontSize 15
#define TitleMargin 8 //标题文本左右边距

@interface UIViewController(IDNPageControllerHidden)

@property(nonatomic,weak) IDNPageController* idnPageController;

@end

// controller信息
@interface IDNPCCInfo : NSObject
@property(nonatomic,strong) NSString* title;
@property(nonatomic) CGFloat textWidth; //标题文本的宽度
@property(nonatomic) CGFloat labelOriginX;
@property(nonatomic) CGFloat labelWidth; //titleWidth加左右margin
@property(nonatomic,strong) UILabel* label;
@end
@implementation IDNPCCInfo
@end

@interface IDNPageController ()
<UIScrollViewDelegate>
{
	UIScrollView* titleBar;
	UIScrollView* scrollView;

	NSInteger numberOfControllers;
	NSMutableDictionary* dicControllers; //key = index, value = controller
	CGSize pageSize; //一个Page的大小

	NSMutableArray* controllerInfos;

	CGFloat barHeight;
	UIFont* titleFont;
	UIView* selectIndicator; //当前选中标题下方的横条
	CGFloat indicatorHeight; //横条高度
}
@end

@implementation IDNPageController

@synthesize selectedIndex=_selectedIndex;

- (CGSize)sizeOfString:(NSString*)string
{
	return [string sizeWithAttributes:@{NSFontAttributeName:self.titleFont}];
}

- (void)initializer
{
	if(dicControllers)
		return;
	dicControllers = [NSMutableDictionary new];
	_titleColor = [UIColor colorWithWhite:0.2 alpha:1.0];
	if(_selectedTitleColor==nil)
		_selectedTitleColor = [UIColor colorWithWhite:0.2 alpha:1.0];
	controllerInfos = [NSMutableArray new];

	UIView* view = self.view;
	view.clipsToBounds = YES;

	titleBar = [[UIScrollView alloc] init];
	titleBar.decelerationRate = UIScrollViewDecelerationRateFast;
	titleBar.showsHorizontalScrollIndicator = NO;
	titleBar.showsVerticalScrollIndicator = NO;
	if(_titleBarColor)
		titleBar.backgroundColor = _titleBarColor;
	else
		titleBar.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	[view addSubview:titleBar];

	selectIndicator = [[UIView alloc] init];
	if(_selectedColor)
		selectIndicator.backgroundColor = _selectedColor;
	else
		selectIndicator.backgroundColor = [UIColor colorWithRed:27/255.0 green:159/255.0 blue:224/255.0 alpha:1.0];
//		selectIndicator.backgroundColor = [UIColor colorWithRed:0/255.0 green:122/255.0 blue:255/255.0 alpha:1.0];
	[titleBar addSubview:selectIndicator];

	scrollView = [[UIScrollView alloc] init];
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.showsHorizontalScrollIndicator = NO;
	[view addSubview:scrollView];

	[titleBar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnTitle:)]];
}

- (UIFont*)titleFont
{
	if(titleFont==nil)
	{
		static UIFont* defaultFont = nil;
		if(defaultFont==nil)
			defaultFont = [UIFont systemFontOfSize:DefaultFontSize];
		titleFont = defaultFont;
	}
	return titleFont;
}
- (void)setTitleFont:(UIFont *)font
{
	titleFont = font;
	if(controllerInfos.count>0)//已经初始化过了
	{
		for (IDNPCCInfo* info in controllerInfos) {
			info.label.font = self.titleFont;
		}
		[self calcTitleTextSizes];
		[self.view setNeedsLayout];
	}
}

- (void)setTitleColor:(UIColor *)titleColor
{
	_titleColor = titleColor;
	if(controllerInfos.count>0)
	{
		for (IDNPCCInfo* info in controllerInfos) {
			info.label.textColor = self.titleColor;
		}
	}
}

- (void)setTitleBarColor:(UIColor *)titleBarColor
{
	_titleBarColor = titleBarColor;
	if(titleBar)
		titleBar.backgroundColor = titleBarColor;
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
	_selectedColor = selectedColor;
	if(selectIndicator)
		selectIndicator.backgroundColor = selectedColor;
}

- (void)tapOnTitle:(UITapGestureRecognizer*)tapGesture
{
	if(numberOfControllers<=0)
		return;
	CGPoint point = [tapGesture locationInView:titleBar];
	NSInteger index = 0;
	for (IDNPCCInfo* info in controllerInfos) {
		if(point.x>=info.labelOriginX && point.x<info.labelOriginX+info.labelWidth)
		{
			if(self.selectedIndex==index)
				return;
			self.selectedIndex = index;
			[self makeSelectedTitleVisibleAnimated:YES];
			return;
		}
		index++;
	}
}

// 加载生成标题Labels
- (void)loadTitles
{
	if(controllerInfos.count) //还未初始化
		return;
	for (NSInteger i = 0;i<_viewControllers.count;i++) {
		UIViewController* c = _viewControllers[i];
		IDNPCCInfo* info = [[IDNPCCInfo alloc] init];
		info.title = c.title;
		[controllerInfos addObject:info];

		UILabel* label = [[UILabel alloc] init];
		label.textAlignment = NSTextAlignmentCenter;
		label.backgroundColor = [UIColor clearColor]; //ios6下label默认背景是白色
		if(_selectedIndex==i)
			label.textColor = _selectedTitleColor;
		else
			label.textColor = _titleColor;
		label.font = self.titleFont;
		label.text = info.title;
		[titleBar addSubview:label];
		info.label = label;
	}
}
// 计算所有标题的文本大小，应该在首次显示或者textFont改变时调用
- (void)calcTitleTextSizes
{
	CGSize defaultSize = [self sizeOfString:@"永远"];
	CGFloat minTextWidth = defaultSize.width;
	barHeight = roundf(defaultSize.height*5.0/3.0);
	if(barHeight<49)
		barHeight = 49;
	indicatorHeight = roundf(barHeight/8.0);
	for (IDNPCCInfo* info in controllerInfos) {
		info.textWidth = roundf([self sizeOfString:info.title].width);
		if (info.textWidth<minTextWidth)
			info.textWidth = minTextWidth;
	}
}
// 计算所有标题的label的大小
- (void)calcTitleLabelSizes
{
	CGSize frameSize = self.view.frame.size;

	CGFloat totalTextWidth = 0;
	for (IDNPCCInfo* info in controllerInfos) {
		info.labelOriginX = totalTextWidth;
		CGFloat labelWidth = info.textWidth + TitleMargin*2;
		info.labelWidth = labelWidth;
		totalTextWidth += labelWidth;
	}
	if(totalTextWidth<=frameSize.width)
	{
		CGFloat ratio = frameSize.width / totalTextWidth;
		CGFloat totalLabelWidth = 0;
		for (IDNPCCInfo* info in controllerInfos) {
			info.labelOriginX = roundf(totalLabelWidth);
			totalLabelWidth += (info.textWidth + TitleMargin*2)*ratio;
			info.labelWidth = roundf(totalLabelWidth) - info.labelOriginX;
		}
	}
}
- (void)layoutTitleLabels
{
	CGFloat labelsWidth = 0;
	NSInteger index = 0;
	for (IDNPCCInfo* info in controllerInfos) {
		info.label.frame = CGRectMake(info.labelOriginX, 0, info.labelWidth, barHeight);
		if(index==_selectedIndex)
			selectIndicator.frame = CGRectMake(info.labelOriginX, barHeight-indicatorHeight, info.labelWidth, indicatorHeight);
		labelsWidth += info.labelWidth;
		index++;
	}
	titleBar.contentSize = CGSizeMake(labelsWidth, barHeight);
}
- (void)makeSelectedTitleVisibleAnimated:(BOOL)animated
{
	IDNPCCInfo* info = controllerInfos[_selectedIndex];
	CGFloat start = info.labelOriginX;
	CGFloat end = start + info.labelWidth;

	if(_selectedIndex>0)
	{
		IDNPCCInfo* linfo = controllerInfos[_selectedIndex-1];
		start = linfo.labelOriginX;
	}
	if(_selectedIndex<numberOfControllers-1)
	{
		IDNPCCInfo* rinfo = controllerInfos[_selectedIndex+1];
		end += rinfo.labelWidth;
	}

	CGPoint titleOffset = titleBar.contentOffset;

	if(end-start>pageSize.width) //控件宽度不足，不能同时放下当前Title及左右两侧Title，此时让当前title居中显示
	{
		CGFloat center = info.labelOriginX+info.labelWidth/2.0;
		titleOffset.x = center-(pageSize.width)/2.0;
	}
	else if(titleOffset.x+pageSize.width<end)
	{
		titleOffset.x = end - pageSize.width;
	}
	else if(titleOffset.x>start)
	{
		titleOffset.x = start;
	}
	else
		return;
	if(titleOffset.x<0)
		titleOffset.x = 0;
	else if(titleOffset.x+pageSize.width>titleBar.contentSize.width)
		titleOffset.x = titleBar.contentSize.width - pageSize.width;

	if(animated)
	{
		[UIView animateWithDuration:0.2 animations:^{
			selectIndicator.frame = CGRectMake(info.labelOriginX, barHeight-indicatorHeight, info.labelWidth, indicatorHeight);
			titleBar.contentOffset = titleOffset;
		}];
	}
	else
		titleBar.contentOffset = titleOffset;
}

- (void)viewDidLayoutSubviews
{
	if(numberOfControllers<=0)
		return;

	BOOL isInit = NO;
	if(dicControllers==nil)
	{
		[self initializer];
		isInit = YES;
	}

	CGSize frameSize = self.view.frame.size;

	//layout标题
	if(controllerInfos.count==0) //还未初始化
	{
		[self loadTitles];
		[self calcTitleTextSizes]; //此函数还计算了barHeight
	}
	if(_isTitleBarOnBottom)
		titleBar.frame = CGRectMake(0, frameSize.height-barHeight, frameSize.width, barHeight);
	else
		titleBar.frame = CGRectMake(0, 0, frameSize.width, barHeight);
	[self calcTitleLabelSizes];
	[self layoutTitleLabels];

	//layout内容
	CGSize oldPageSize = pageSize;

	pageSize.width = frameSize.width;
	pageSize.height = frameSize.height - barHeight;
	if(pageSize.height<0)
		pageSize.height = 0;
	if(_isTitleBarOnBottom)
		scrollView.frame = CGRectMake(0, 0, pageSize.width, pageSize.height);
	else
		scrollView.frame = CGRectMake(0, barHeight, pageSize.width, pageSize.height);
	scrollView.contentSize = CGSizeMake(pageSize.width*numberOfControllers, pageSize.height);
	
	CGFloat ratio;
	if(oldPageSize.width>0)
		ratio = pageSize.width / oldPageSize.width;
	else
		ratio = 0;

	if(isInit) //可能在view初始化前，修改了selectedIndex
	{
		scrollView.contentOffset = CGPointMake(pageSize.width*_selectedIndex, 0);
		ratio = 1;
	}
	scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x*ratio, 0);

	if(pageSize.width>0 && dicControllers.count==0) //首次加载controllers
		[self loadVisibleViews];
	[self layoutVisibleViews];
}

- (void)setViewControllers:(NSArray *)viewControllers
{
	viewControllers = [viewControllers copy];
	
	for (UIViewController* c in dicControllers.allValues) {
		[c.view removeFromSuperview];
		c.idnPageController = nil;
	}
	[dicControllers removeAllObjects];
	for (IDNPCCInfo* info in controllerInfos) {
		[info.label removeFromSuperview];
	}
	[controllerInfos removeAllObjects];
	titleBar.frame = CGRectZero;
	titleBar.contentSize = CGSizeZero;
	titleBar.contentOffset = CGPointZero;
	scrollView.frame = CGRectZero;
	scrollView.contentOffset = CGPointZero;

	_viewControllers = viewControllers;
	numberOfControllers = viewControllers.count;
	_selectedIndex = 0;

	for (UIViewController* c in _viewControllers) {
		c.idnPageController = self;
	}
	if(titleBar) //已经loadView过
		[self.view setNeedsLayout];

	if(numberOfControllers>0 && [_delegate respondsToSelector:@selector(pageController:didSelectViewControllerAtIndex:)])
		[_delegate pageController:self didSelectViewControllerAtIndex:_selectedIndex];
}

- (NSInteger)selectedIndex
{
	if(numberOfControllers<=0)
		return -1;
	return _selectedIndex;
}
- (void)setSelectedIndex:(NSInteger)selectedIndex
{
	[self setSelectedIndex:selectedIndex animated:NO onlyTitle:NO];
}
- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated onlyTitle:(BOOL)onlyTitle
{
	if(numberOfControllers==0)
		return;
	NSInteger oldIndex = _selectedIndex;

	_selectedIndex = selectedIndex; //_selectedIndex与selectedIndex即使相等也不return，因为有可能selectedIndex没改变，但contentOffset改变了，此时相当于将contentOffset恢复到selectedIndex对应的位置上。

	if(titleBar==nil) //还没有初始化
	{
		if((oldIndex != _selectedIndex) && [_delegate respondsToSelector:@selector(pageController:didSelectViewControllerAtIndex:)])
			[_delegate pageController:self didSelectViewControllerAtIndex:_selectedIndex];
		return;
	}

	if(onlyTitle==NO)
		[scrollView setContentOffset:[self offsetFromIndex:_selectedIndex] animated:animated];
	[self loadVisibleViews];
	[self layoutVisibleViews];

	if(_selectedIndex!=oldIndex)
	{
		if(oldIndex>=0)
		{
			IDNPCCInfo* oldinfo = controllerInfos[oldIndex];
			oldinfo.label.textColor = _titleColor;
		}
		IDNPCCInfo* info = controllerInfos[_selectedIndex];
		info.label.textColor = _selectedTitleColor;
		if(animated)
		{
			[UIView animateWithDuration:0.2 animations:^{
				selectIndicator.frame = CGRectMake(info.labelOriginX, barHeight-indicatorHeight, info.labelWidth, indicatorHeight);
			}];
		}
		else
		{
			selectIndicator.frame = CGRectMake(info.labelOriginX, barHeight-indicatorHeight, info.labelWidth, indicatorHeight);
		}

		if([_delegate respondsToSelector:@selector(pageController:didSelectViewControllerAtIndex:)])
			[_delegate pageController:self didSelectViewControllerAtIndex:_selectedIndex];
	}
}

- (void)setIsTitleBarOnBottom:(BOOL)isTitleBarOnBottom
{
	if(isTitleBarOnBottom==_isTitleBarOnBottom)
		return;
	_isTitleBarOnBottom = isTitleBarOnBottom;
	[self.view setNeedsLayout];
}

- (void)setSelectedTitleColor:(UIColor *)selectedTitleColor
{
	if(_selectedTitleColor == selectedTitleColor)
		return;
	_selectedTitleColor = selectedTitleColor;
	if(_selectedIndex>=0)
	{
		IDNPCCInfo* info = controllerInfos[_selectedIndex];
		info.label.textColor = _selectedTitleColor;
	}
}
// 加载可见view，应该在currentIndex改变后调用
- (void)loadVisibleViews
{
	NSArray* newVisibles = [self calcVisibleViews];
	NSArray* oldVisibles = dicControllers.allKeys;
	NSMutableSet* set = [NSMutableSet setWithArray:oldVisibles];
	[set addObjectsFromArray:newVisibles];
	for (NSNumber* indexNumber in set) {

		BOOL isOld,isNew;
		if ([oldVisibles containsObject:indexNumber])
			isOld = YES;
		else
			isOld = NO;
		if([newVisibles containsObject:indexNumber])
			isNew = YES;
		else
			isNew = NO;

		if(isOld && isNew) //一直可见
			continue;
		else if(isOld && isNew==NO) //之前可见，现在不可见
		{
			UIViewController* c = dicControllers[indexNumber];
			[c.view removeFromSuperview];
			[dicControllers removeObjectForKey:indexNumber];
		}
		else if(isOld==NO && isNew) //之前不可见，现在可见
		{
			NSInteger index = indexNumber.integerValue;
			UIViewController* c = _viewControllers[index];
			[scrollView addSubview:c.view];
			dicControllers[indexNumber] = c;
		}
	}
}

// 重新放置unitViews
- (void)layoutVisibleViews
{
	for (NSNumber* indexNumber in dicControllers.allKeys) {
		UIViewController* c = dicControllers[indexNumber];
		[self layoutView:c.view index:indexNumber.integerValue];
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
	NSInteger i = scrollView.contentOffset.x / pageSize.width + 0.5;
	if(i!=_selectedIndex)
	{
		[self setSelectedIndex:i animated:YES onlyTitle:YES];
		[self makeSelectedTitleVisibleAnimated:YES];
	}
}

#pragma mark 

// 根据index计算offset
- (CGPoint)offsetFromIndex:(NSInteger)index
{
	return CGPointMake(pageSize.width*index, 0);
}
// 根据offset计算index
- (NSInteger)indexFromOffset:(CGPoint)offset
{
	NSInteger index = roundf(offset.x/pageSize.width);
	if(index<0)
		index = 0;
	else if(index>=numberOfControllers)
		index = numberOfControllers - 1;
	return index;
}

- (NSArray*)calcVisibleViews
{
	if(numberOfControllers==0)
		return nil;
	NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:3];
	if(_selectedIndex>0)
		[array addObject:@(_selectedIndex-1)];
	[array addObject:@(_selectedIndex)];
	if(_selectedIndex<numberOfControllers-1)
		[array addObject:@(_selectedIndex+1)];
	return array;
}

- (void)layoutView:(UIView*)view index:(NSInteger)index
{
	view.frame = CGRectMake(pageSize.width*index, 0, pageSize.width, pageSize.height);
}

@end

#pragma mark Category

@interface IDNPageControllerHiddenWeakObj : NSObject
@property(nonatomic,weak) id weakObj;
@end
@implementation IDNPageControllerHiddenWeakObj
@end

@implementation UIViewController(IDNPageControllerHidden)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfIDNPageControllerHiddenBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (void)setIdnPageController:(IDNPageController *)idnPageController
{
	NSMutableDictionary* dic = [self dictionaryOfIDNPageControllerHiddenBindData];
	IDNPageControllerHiddenWeakObj* weakObj = [IDNPageControllerHiddenWeakObj new];
	weakObj.weakObj = idnPageController;
	dic[@"idnPageController"] = weakObj;
}

- (IDNPageController*)idnPageController
{
	NSMutableDictionary* dic = [self dictionaryOfIDNPageControllerHiddenBindData];
	IDNPageControllerHiddenWeakObj* weakObj = dic[@"idnPageController"];
	return weakObj.weakObj;
}

@end
