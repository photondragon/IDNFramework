#import "IDNSideMenuController.h"

#define SideViewRightMargin	40.0 //左侧界面距离屏幕右边的距离。也就是当主界面滑向右侧后，最后还露出40Point
#define SideViewTopMargin 64 //在nav bar之下
#define ThrowOffMinVelocity 100.0 //甩动操作的最小速度。滑动操作结束时的速度大于这个值便是甩动操作，会根据甩动的方向决定是显出还是收起SideController
#define SlideMinTranslation 20.0//滑动的最小位移。
#define SlideSwitchMinTranslation 50.0 //滑动切换的最小位移。大于这个值则会切换现出/收起状态（只在非甩动操作时检测这个值）
#define AnimationDuration 0.25

@interface IDNSideMenuController ()
<UIGestureRecognizerDelegate>
{
	CGFloat slideMax; //最大滑动距离
	CGFloat slideLength; //当前滑动距离
	BOOL isPaning; //是否识别出Pan手势。识别出Pan手势时并不会立即滑动，要根据移动方向和位移量来决定是否进入滑动状态。
	BOOL isSliding; //是否正在滑动。进入滑动状态后mainController.view会随着手指作水平移动
	CGPoint slideTranslation; //当前的滑动位移
	UIControl* maskView; //当显示SideView时，用于盖在MainView之上，防止点击到MainView中的元素。
}

@end

@implementation IDNSideMenuController

- (void)initialize
{
	if(_mainController==nil)
	{
		CGSize size = self.view.frame.size;
		slideMax = size.width - SideViewRightMargin;
		slideLength = 0;

		_mainController = [[UINavigationController alloc] init];
		_mainController.navigationBar.translucent = NO;
		_mainController.view.frame = CGRectMake(0, 0, size.width, size.height);
		_mainController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:_mainController.view];
		
		maskView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
		maskView.userInteractionEnabled = YES;
		maskView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
		maskView.hidden = YES;
		[self.view addSubview:maskView];
		UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMaskView:)];
//		tapGesture.delegate = self;
		[maskView addGestureRecognizer:tapGesture];
		
		UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
		panGestureRecognizer.delegate = self;
		panGestureRecognizer.maximumNumberOfTouches = 1;
		[panGestureRecognizer requireGestureRecognizerToFail:_mainController.interactivePopGestureRecognizer];
		[self.view addGestureRecognizer:panGestureRecognizer];
		_panGestureRecognizer = panGestureRecognizer;
	}
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

- (void)setSideController:(UIViewController *)sideController
{
	if(_sideController==sideController)
		return;
	[self removeSideView];
	_sideController = sideController;
	[self addSideView];
}
- (void)addSideView
{
	if(_sideController)
	{
		if(_sideController.view.superview)//已经添加
			return;
		CGFloat pixelLen = 1.0/[UIScreen mainScreen].scale;
		CGSize size = self.view.frame.size;
		size.width -= SideViewRightMargin;
		size.height -= (SideViewTopMargin+pixelLen);
		_sideController.view.frame = CGRectMake(-size.width, (SideViewTopMargin+pixelLen), size.width-4, size.height);
		_sideController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_sideController.view.layer.shadowOpacity = 0.5;
		_sideController.view.layer.shadowOffset = CGSizeMake(1, 2);
		_sideController.view.layer.shadowRadius = 1.0;
		[self.view addSubview:_sideController.view];
	}
}
- (void)removeSideView
{
	[_sideController.view removeFromSuperview];
}

- (void)tapOnMaskView:(UITapGestureRecognizer*)tapGesture
{
	[self showSideController:NO animated:YES];//收起SideView
}

- (void)pan:(UIPanGestureRecognizer*)panGesture
{
	if (panGesture.state==UIGestureRecognizerStateBegan)
	{
		if(_isShowingSideController==NO)//没有显示SideView的情况下
		{
			CGPoint point = [panGesture locationInView:self.view];
			CGPoint translation = [panGesture translationInView:self.view];
			CGPoint touchStartPoint;
			touchStartPoint.x = point.x - translation.x;
			touchStartPoint.y = point.y - translation.y;
//			NSLog(@"test:%@",[NSValue valueWithCGPoint:touchStartPoint]);
			if(touchStartPoint.x>30.0)//现出SideView的手势的起始位置必须在最左边，否则取消手势
			{
				panGesture.enabled = NO;
				panGesture.enabled = YES;
				return;
			}
		}
		isPaning = YES;
		slideTranslation = CGPointZero;
	}
	else if(panGesture.state==UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [panGesture translationInView:self.view];
		CGPoint delta;//相对于上一次的位移量
		delta.x = translation.x-slideTranslation.x;
		delta.y = translation.y-slideTranslation.y;
		slideTranslation = translation;
		
		if(isSliding==NO)
		{
			if(translation.x*translation.x+translation.y*translation.y > SlideMinTranslation*SlideMinTranslation)//总位移足够长（约20.0）
			{
				if ((translation.x>=0 ? translation.x : -translation.x) > (translation.y>=0 ? translation.y : -translation.y))//水平移动更多
				{
					if( (_isShowingSideController && translation.x>0) || //当前已经现出SideView了，再一次向右滑动
					   (_isShowingSideController==NO && translation.x<0) ) ////当前已经收起SideView了，再一次向左滑动
					{//取消PAN手势
						panGesture.enabled = NO;
						panGesture.enabled = YES;
						return;
					}
					isSliding = YES; //进入滑动状态
					if(_isShowingSideController==NO)
					{
						[[self findFirstResponderInView:self.view] resignFirstResponder];//取消输入焦点
						[[self findFirstResponderInView:self.view] resignFirstResponder];//再一次调用是因为在上一次resignFirstResponder中有可能会调用另一个对象的becomeFirstResponder方法，导致键盘不消失，这可能是一个BUG
					}
				}
				else//垂直位移更多，取消PAN手势
				{
					panGesture.enabled = NO;
					panGesture.enabled = YES;
					return;
				}
			}
		}
		
		if(isSliding)
		{
			slideLength += delta.x;
			if(slideLength<0)
				slideLength = 0;
			else if(slideLength>slideMax)
				slideLength = slideMax;
			CGRect sideFrame = _sideController.view.frame;
			sideFrame.origin.x = slideLength-slideMax;
			_sideController.view.frame = sideFrame;
			
		}
//		NSLog(@"%@ %.0f",[NSValue valueWithCGPoint:delta],slideLength);
	}
	else if (panGesture.state == UIGestureRecognizerStateEnded ||
			 panGesture.state == UIGestureRecognizerStateCancelled)
	{
		isPaning = NO;
		
		if(isSliding)
		{
			isSliding = NO;

			CGPoint velocity = [panGesture velocityInView:self.view];
			if(velocity.x<ThrowOffMinVelocity && velocity.x>-ThrowOffMinVelocity)//滑动结束的速度比较慢，根据当前滑动位置和滑动前的起始状态来决定是现出还是收起SideController
			{
				if(_isShowingSideController)//起始状态是现出SideView
				{
					if(slideMax - slideLength>SlideSwitchMinTranslation)//收起
					{
						[self showSideController:NO animated:YES];
					}
					else//现出
					{
						[self showSideController:YES animated:YES];
					}
				}
				else//起始状态是收起SideView
				{
					if(slideLength>SlideSwitchMinTranslation)//现出
					{
						[self showSideController:YES animated:YES];
					}
					else//收起
					{
						[self showSideController:NO animated:YES];
					}
				}
			}
			else if(velocity.x>ThrowOffMinVelocity)//向右甩，现出
			{
				[self showSideController:YES animated:YES];
			}
			else if(velocity.x<-ThrowOffMinVelocity)//向左甩，收起
			{
				[self showSideController:NO animated:YES];
			}
		}
	}
}

- (void)showSideController:(BOOL)showSide
{
	if(showSide)
	{
		[[self findFirstResponderInView:self.view] resignFirstResponder];//取消输入焦点
		[[self findFirstResponderInView:self.view] resignFirstResponder];//再一次调用是因为在上一次resignFirstResponder中有可能会调用另一个对象的becomeFirstResponder方法，导致键盘不消失，这可能是一个BUG
	}
	[self showSideController:showSide animated:YES];
}
- (void)showSideController:(BOOL)showSide animated:(BOOL)animated
{
	_isShowingSideController = showSide;
	
	CGRect sideFrame = _sideController.view.frame;
	CGFloat animationLength;
	if(showSide)//现出SideView
	{
		sideFrame.origin.x = 0;
		animationLength = slideMax - slideLength;
		slideLength = slideMax;
		maskView.hidden = NO;
	}
	else
	{
		sideFrame.origin.x = -slideMax;
		animationLength = slideLength;
		slideLength = 0;
		maskView.hidden = YES;
	}
	
	NSTimeInterval animationDuration;
	if(animationLength>0)
	{
		animationDuration = AnimationDuration*animationLength/slideMax;
		if(animationDuration<0.1)//动画至少0.1秒
			animationDuration = 0.1;
	}
	else
		animationDuration = 0;
	
	if(animationDuration>0 && animated)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:animationDuration];

		_sideController.view.frame = sideFrame;

		[UIView commitAnimations];
	}
	else
		_sideController.view.frame = sideFrame;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
//	UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer*)gestureRecognizer;
//	CGPoint translation = [panGesture translationInView:self.view];
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

@end
