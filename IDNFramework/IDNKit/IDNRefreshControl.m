//
//  IDNRefreshControl.m
//  IDNFramework
//
//  Created by photondragon on 15/5/17.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNRefreshControl.h"
#import <objc/runtime.h>

//弧度转角度
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
//角度转弧度
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define TextColor [UIColor colorWithWhite:0.6 alpha:1.0]
#define CakeColor [UIColor colorWithWhite:0.7 alpha:1.0]

#define RefreshControlHeight 60 //刷新控件的默认高度
#define ProgressViewSize 17 //进度提示View（饼视图）的大小

enum IDNRefreshPullState
{
	IDNRefreshControlStateNormal=0, //正常状态。显示“下拉显示更多”
	IDNRefreshControlStatePulling, //正在拉，还没拉到位。可以显示“下拉显示更多”+进度条（显示是否拉到位）
	IDNRefreshControlStatePulled, //拉到位状态。可以显示“松开加载更多”+进度条（100%）
};

//指示拉的进度的饼状视图。
@interface IDNRefreshControlCakeView : UIView
@property(nonatomic) float ratio; //比例[0, 1.0]
@property(nonatomic,copy) UIColor* color; //饼的颜色
@end
@implementation IDNRefreshControlCakeView

- (CGSize)intrinsicContentSize
{
	return CGSizeMake(ProgressViewSize, ProgressViewSize);
}

- (void)setRatio:(float)ratio
{
	if(ratio<0)
		ratio = 0;
	else if(ratio>1.0)
		ratio = 1.0;
	if(_ratio == ratio)
		return;
	_ratio = ratio;
	[self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect
{
	CGSize framesize = self.frame.size;
	CGFloat pixelWidth = 1.0/[UIScreen mainScreen].scale;
	CGFloat lineWidth = 1.0;
	CGFloat length = framesize.width < framesize.height ? framesize.width : framesize.height;
	CGFloat radius = length/2-pixelWidth-lineWidth/2;
	CGPoint center = CGPointMake(framesize.width/2, framesize.height/2);

	[_color set];

	UIBezierPath* path = [UIBezierPath bezierPath];
	[path addArcWithCenter:center
					radius:radius
				startAngle:DEGREES_TO_RADIANS(-90)
				  endAngle:DEGREES_TO_RADIANS(-90+360.0*self.ratio)
				 clockwise:YES];
	[path addLineToPoint:center];
	[path addLineToPoint:CGPointMake(center.x, center.y-radius)];
	[path fill];

	[path removeAllPoints];
	[path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI*2 clockwise:YES];
	path.lineWidth = lineWidth;
	[path stroke];
}
@end

@interface IDNRefreshControl()
{
	BOOL isAtBottom;
	CGFloat addedInsetLength;
}

@property(nonatomic) enum IDNRefreshPullState pullState;
@property(nonatomic, weak) IDNRefreshControlCakeView* cakeView;
@property(nonatomic, weak) UILabel* pullLabelView;
@property(nonatomic, weak) UILabel* loadingLabelView;
@property(nonatomic, weak) UIActivityIndicatorView* loadingView; //旋转菊花

@end
@implementation IDNRefreshControl

- (void)initialize
{
	if(self.cakeView==nil)
	{
		//不采用autoLayout方案，因为ios7.1上的tableView的实现有Bug，当向其加入subview时，如果用autolayout，就会出异常。只能用autoresizingMask
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		//self.translatesAutoresizingMaskIntoConstraints = NO;

		_maxPullingDistance = 80.0;
		_minPullingDistance = 30.0;

		if(isAtBottom)
		{
			self.normalTitle = [[NSAttributedString alloc] initWithString:@"加载更多"];
			self.pullingTitle = [[NSAttributedString alloc] initWithString:@"加载更多"];
			self.pulledTitle = [[NSAttributedString alloc] initWithString:@"松开加载"];
			self.refreshingTitle = [[NSAttributedString alloc] initWithString:@"正在加载"];
		}
		else
		{
			self.normalTitle = [[NSAttributedString alloc] initWithString:@"下拉刷新"];
			self.pullingTitle = [[NSAttributedString alloc] initWithString:@"下拉刷新"];
			self.pulledTitle = [[NSAttributedString alloc] initWithString:@"松开刷新"];
			self.refreshingTitle = [[NSAttributedString alloc] initWithString:@"正在刷新"];
		}

		IDNRefreshControlCakeView* cakeView = [[IDNRefreshControlCakeView alloc] init];//WithFrame:CGRectMake(0, 0, 30, 30)];
		cakeView.translatesAutoresizingMaskIntoConstraints = NO;
		cakeView.backgroundColor = [UIColor clearColor];
		cakeView.color = CakeColor;
		[self addSubview:cakeView];
		self.cakeView = cakeView;

		UIActivityIndicatorView* loadingView = [[UIActivityIndicatorView alloc] init];//WithFrame:CGRectMake(0, 0, 30, 30)];
		loadingView.translatesAutoresizingMaskIntoConstraints = NO;
		loadingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		loadingView.hidden = YES;
		[self addSubview:loadingView];
		self.loadingView = loadingView;

		UIFont* font = [UIFont systemFontOfSize:16];
		UILabel* pullLabelView = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 290, 30)];
		pullLabelView.textColor = TextColor;
		pullLabelView.font = font;
		pullLabelView.translatesAutoresizingMaskIntoConstraints = NO;
		pullLabelView.attributedText = self.normalTitle;
		[self addSubview:pullLabelView];
		self.pullLabelView = pullLabelView;

		UILabel* refreshingLabelView = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 290, 30)];
		refreshingLabelView.textColor = TextColor;
		refreshingLabelView.font = font;
		refreshingLabelView.translatesAutoresizingMaskIntoConstraints = NO;
		refreshingLabelView.attributedText = self.refreshingTitle;
		refreshingLabelView.hidden = YES;
		[self addSubview:refreshingLabelView];
		self.loadingLabelView = refreshingLabelView;

		// 子控件垂直居中
		[self addConstraint:[NSLayoutConstraint constraintWithItem:cakeView attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterY
														multiplier:1.0 constant:0]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:loadingView attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterY
														multiplier:1.0 constant:0]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:pullLabelView attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterY
														multiplier:1.0 constant:0]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:refreshingLabelView attribute:NSLayoutAttributeCenterY
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterY
														multiplier:1.0 constant:0]];

		[self addConstraint:[NSLayoutConstraint constraintWithItem:cakeView attribute:NSLayoutAttributeLeading
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterX
														multiplier:1.0 constant:-60]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:loadingView attribute:NSLayoutAttributeLeading
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterX
														multiplier:1.0 constant:-60]];

		[self addConstraint:[NSLayoutConstraint constraintWithItem:pullLabelView attribute:NSLayoutAttributeLeading
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterX
														multiplier:1.0 constant:-30]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:refreshingLabelView attribute:NSLayoutAttributeLeading
														 relatedBy:NSLayoutRelationEqual
															toItem:self attribute:NSLayoutAttributeCenterX
														multiplier:1.0 constant:-30]];

		//		// 控件高度约束
		//		NSLayoutConstraint* constraintHeight = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight
		//																 relatedBy:NSLayoutRelationEqual
		//																	toItem:nil attribute:NSLayoutAttributeNotAnAttribute
		//																multiplier:0 constant:RefreshControlHeight];
		//		[self addConstraint:constraintHeight];
		//		[self setNeedsLayout];
	}
}

- (instancetype)initAtBottom:(BOOL)atBottom
{
	self = [super initWithFrame:CGRectZero];
	if (self) {
		isAtBottom = atBottom;
		[self initialize];
	}
	return self;
}

- (instancetype)init
{
	self = [super initWithFrame:CGRectZero];
	if (self) {
		[self initialize];
	}
	return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initialize];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initialize];
	}
	return self;
}

- (BOOL)isMaxPulling
{
	return _pulledDistance>=_maxPullingDistance;
}
- (void)setMaxPullingDistance:(float)maxPullingDistance
{
	if(maxPullingDistance<RefreshControlHeight)
		maxPullingDistance = RefreshControlHeight;
	if(maxPullingDistance<_minPullingDistance+30)
		maxPullingDistance = _minPullingDistance+30;
	if(_maxPullingDistance==maxPullingDistance)
		return;
	_maxPullingDistance = maxPullingDistance;
	[self updatePercent];
}
- (void)setMinPullingDistance:(float)minPullingDistance
{
	if(minPullingDistance<20.0)
		minPullingDistance = 20.0;
	if(minPullingDistance>_maxPullingDistance-30)
		minPullingDistance = _maxPullingDistance-30;
	if(_minPullingDistance==minPullingDistance)
		return;
	_minPullingDistance = minPullingDistance;
	[self updatePercent];
}
- (void)setPulledDistance:(float)pulledDistance
{
	if(pulledDistance<0)
		pulledDistance = 0;
	if(_pulledDistance == pulledDistance)
		return;
	_pulledDistance = pulledDistance;
	[self updatePercent];
}
- (void)updatePercent
{
	float ratio = (_pulledDistance-_minPullingDistance)/(_maxPullingDistance-_minPullingDistance);
	if(ratio<0)
		ratio = 0;
	self.cakeView.ratio = ratio;
	if(ratio<=0)
		self.pullState = IDNRefreshControlStateNormal;
	if(ratio>=1.0)
		self.pullState = IDNRefreshControlStatePulled;
	else
		self.pullState = IDNRefreshControlStatePulling;
}

- (void)setNormalTitle:(NSAttributedString *)normalTitle
{
	if([_normalTitle isEqualToAttributedString:normalTitle])
		return;
	_normalTitle = normalTitle;
	if(self.pullState==IDNRefreshControlStateNormal)
		self.pullLabelView.attributedText = normalTitle;
}

- (void)setPullingTitle:(NSAttributedString *)pullingTitle
{
	if([_pullingTitle isEqualToAttributedString:pullingTitle])
		return;
	_pullingTitle = pullingTitle;
	if(self.pullState==IDNRefreshControlStatePulling)
		self.pullLabelView.attributedText = pullingTitle;
}
- (void)setPulledTitle:(NSAttributedString *)pulledTitle
{
	if([_pulledTitle isEqualToAttributedString:pulledTitle])
		return;
	_pulledTitle = pulledTitle;
	if(self.pullState==IDNRefreshControlStatePulled)
		self.pullLabelView.attributedText = pulledTitle;
}
- (void)setRefreshingTitle:(NSAttributedString *)refreshingTitle
{
	if([_refreshingTitle isEqualToAttributedString:refreshingTitle])
		return;
	_refreshingTitle = refreshingTitle;
	self.loadingLabelView.attributedText = refreshingTitle;
}

- (void)setRefreshing:(BOOL)refreshing
{
	if(_refreshing==refreshing)
		return;
	_refreshing = refreshing;
	if(refreshing)//进入刷新状态
	{
		self.cakeView.hidden = YES;
		self.pullLabelView.hidden = YES;
		self.loadingView.hidden = NO;
		self.loadingLabelView.hidden = NO;
		[self.loadingView startAnimating];

		if(addedInsetLength==0)
		{
			addedInsetLength = self.pulledDistance;
			if(addedInsetLength<40)
				addedInsetLength = 40;
			UIEdgeInsets inset = self.containerView.contentInset;
			if(isAtBottom)
				inset.bottom += addedInsetLength;
			else
				inset.top += addedInsetLength;
			self.containerView.contentInset = inset;
		}
	}
	else//退出刷新状态
	{
		self.cakeView.hidden = NO;
		self.pullLabelView.hidden = NO;
		self.loadingView.hidden = YES;
		self.loadingLabelView.hidden = YES;
		[self.loadingView stopAnimating];

		UIEdgeInsets inset = self.containerView.contentInset;
		if(addedInsetLength>0)
		{
			if(isAtBottom)
				inset.bottom -= addedInsetLength;
			else
				inset.top -= addedInsetLength;
			addedInsetLength = 0;

			UIScrollView* containerView = self.containerView;
			if (isAtBottom) //加载更多
			{
				CGPoint offset = containerView.contentOffset;
				[containerView setContentOffset:offset animated:YES];//让contentView立刻停止滚动，否则改变inset后界面可能会产生跳变。

				containerView.contentInset = inset;

				CGSize frameSize = containerView.frame.size;
				CGSize contentSize = containerView.contentSize;
				CGFloat maxOffset = contentSize.height-frameSize.height;
				if(maxOffset<0)
					maxOffset = 0;

				if(offset.y<0)
					offset.y = 0;
				else if(offset.y>maxOffset)
					offset.y = maxOffset;
				containerView.contentOffset = offset; //改变底部inset后，保持contentOffset不变，避免界面发生跳动
			}
			else
			{
				[containerView setContentOffset:containerView.contentOffset animated:YES];//让contentView立刻停止滚动，否则改变inset后界面可能会产生跳变。
				[UIView animateWithDuration:0.3 animations:^{
					containerView.contentInset = inset;
				}];
			}
		}
	}
}

- (void)setPullState:(enum IDNRefreshPullState)state
{
	if(_pullState==state)
		return;
	_pullState = state;
	if(_pullState==IDNRefreshControlStateNormal)
		self.pullLabelView.attributedText = self.normalTitle;
	else if(_pullState==IDNRefreshControlStatePulling)
		self.pullLabelView.attributedText = self.pullingTitle;
	else if(_pullState==IDNRefreshControlStatePulled)
		self.pullLabelView.attributedText = self.pulledTitle;
}

- (void)dragEnded
{
	if (self.enabled == YES && self.hidden==NO && self.refreshing==NO && self.isMaxPulling) {
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	//之所以在这里注册/删除KVO，是因为当[containerView dealloc]时不会自动删除KVO，导致程序崩溃。本来这些代码是在setContainerView:中的。
	//不在能willMoveToSuperview:nil中实现这些功能。因为函数的调用顺序是[self willMoveToWindow:nil], [containerView dealloc], [self willMoveToSuperview:nil]
	//在[containerView dealloc]之后是无法删除KVO的
	if(newWindow)//加入
	{
		if(isAtBottom)//上拉加载更多控件
			[_containerView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
		[_containerView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
	}
	else
	{
		if(isAtBottom)
			[_containerView removeObserver:self forKeyPath:@"contentSize"];
		[_containerView removeObserver:self forKeyPath:@"contentOffset"];
	}
}

- (void)setContainerView:(UIScrollView *)containerView
{
	if(_containerView==containerView)
		return;
	if(_containerView)
	{
		[_containerView.panGestureRecognizer removeTarget:self action:@selector(panGestureRecognizerStateUpdate:)];
		[self removeFromSuperview];
	}
	_containerView = containerView;
	if(containerView==nil)//新containerView为空
		return;

	[containerView.panGestureRecognizer addTarget:self action:@selector(panGestureRecognizerStateUpdate:)];

	UIEdgeInsets inset = containerView.contentInset;
	if(isAtBottom)//上拉加载更多控件
	{
		CGRect frame = CGRectMake(0, containerView.contentSize.height+inset.top+inset.bottom, containerView.frame.size.width, RefreshControlHeight);
		if(frame.origin.y<containerView.frame.size.height)
			frame.origin.y = containerView.frame.size.height;
		self.frame = frame;
	}
	else//下拉刷新控件
		self.frame = CGRectMake(0, -RefreshControlHeight-inset.top, containerView.frame.size.width, RefreshControlHeight);
	[containerView addSubview:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{

	if([keyPath isEqualToString:@"contentSize"])
	{
		NSValue* sizeValue = [change objectForKey:NSKeyValueChangeNewKey];
		CGRect frame = self.frame;
		frame.origin.y = [sizeValue CGSizeValue].height;
		if(frame.origin.y<_containerView.frame.size.height)
			frame.origin.y = _containerView.frame.size.height;
		self.frame = frame;
	}
	else if([keyPath isEqualToString:@"contentOffset"])
	{
		CGFloat offset = self.containerView.contentOffset.y;

		if(isAtBottom)
		{
			CGFloat maxOffset = self.containerView.contentSize.height - self.containerView.frame.size.height;
			if(maxOffset<0)
				maxOffset = 0;
			CGFloat pulled = offset - maxOffset;
			if(pulled<0)
				pulled = 0;
			self.pulledDistance = pulled;
		}
		else
		{
			CGFloat pulledDistance = -offset;
			if(pulledDistance<0)
				pulledDistance = 0;
			self.pulledDistance = pulledDistance;
		}
	}
}

- (void)panGestureRecognizerStateUpdate:(UIGestureRecognizer*)recognizer
{
	if(recognizer.state == UIGestureRecognizerStateEnded)//相当于containerView的dragging end
		[self dragEnded];
}

@end

static char associatedObjectKeyIDNRefreshControl = 0;

@implementation UITableView(IDNRefreshControl)

- (NSMutableDictionary*)dictionaryOfIDNRefreshControl
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &associatedObjectKeyIDNRefreshControl);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &associatedObjectKeyIDNRefreshControl, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (IDNRefreshControl*)topRefreshControl
{
	NSMutableDictionary* dic = [self dictionaryOfIDNRefreshControl];
	IDNRefreshControl* refreshControl = dic[@"topRefreshControl"];
	if(refreshControl==nil)
	{
		refreshControl = [[IDNRefreshControl alloc] init];
		refreshControl.containerView = self;
		dic[@"topRefreshControl"] = refreshControl;
	}
	return refreshControl;
}

- (IDNRefreshControl*)bottomRefreshControl
{
	NSMutableDictionary* dic = [self dictionaryOfIDNRefreshControl];
	IDNRefreshControl* refreshControl = dic[@"bottomRefreshControl"];
	if(refreshControl==nil)
	{
		refreshControl = [[IDNRefreshControl alloc] initAtBottom:YES];
		refreshControl.containerView = self;
		dic[@"bottomRefreshControl"] = refreshControl;
	}
	return refreshControl;
}

- (void)refreshRowsModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added inSection:(NSInteger)section
{
	if(section<0)
		return;
	else if(section>=self.numberOfSections)
		return;
	[self beginUpdates];
	if (modified.count)
	{
		NSMutableArray* indexPathes = [NSMutableArray array];
		for (NSNumber* index in modified) {
			[indexPathes addObject:[NSIndexPath indexPathForRow:[index integerValue] inSection:section]];
		}
		[self reloadRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationAutomatic]; // 在beginUpdates和endUpdates之间调用此方法，indics应该是基于原列表的index。而
	}
	if (deleted.count)
	{
		NSMutableArray* indexPathes = [NSMutableArray array];
		for (NSNumber* index in deleted) {
			[indexPathes addObject:[NSIndexPath indexPathForRow:[index integerValue] inSection:section]];
		}
		[self deleteRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	if (added.count)
	{
		NSMutableArray* indexPathes = [NSMutableArray array];
		for (NSNumber* index in added) {
			[indexPathes addObject:[NSIndexPath indexPathForRow:[index integerValue] inSection:section]];
		}
		[self insertRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	[self endUpdates];
}
@end
