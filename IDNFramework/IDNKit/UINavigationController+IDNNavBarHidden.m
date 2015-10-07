//
//  UINavigationController+IDNNavBarHidden.h
//
//  Created by mahj on 15/9/28.

#import "UINavigationController+IDNNavBarHidden.h"
#import <objc/runtime.h>

@interface IDNNavBarHiddenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic,weak) UIView* touchedView;

@end

@implementation IDNNavBarHiddenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
	CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
	NSLog(@"%@", [NSValue valueWithCGPoint:translation]);
	if (self.navigationController.viewControllers.count <= 1)
		return NO;
	
	// Ignore pan gesture when the navigation controller is currently in transition.
	if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
		return NO;
	}
	
	// Prevent calling the handler when the gesture begins in an opposite direction.
	if (translation.x < 0 || ABS(translation.x)<ABS(translation.y)) {
		return NO;
	}
	
	//取消所有其它的手势
	UIView* view = self.touchedView;
	while (view)
	{
		for (UIGestureRecognizer* g in view.gestureRecognizers) {
			if((__bridge void*)g==(__bridge void*)gestureRecognizer)
				continue;
			if(g.enabled)
			{
				g.enabled = NO;
				g.enabled = YES;
			}
		}
		if(view==gestureRecognizer.view)
			break;
		view = view.superview;
	}
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	self.touchedView = touch.view;
	return YES;
}

@end

@implementation UINavigationController(IDNNavBarHidden)

static char bindDictionaryKey = 0;

- (NSMutableDictionary*)bindedDictOfUINavigationControllerIDNNavBarHidden
{
	return objc_getAssociatedObject(self, &bindDictionaryKey);
}
- (NSMutableDictionary*)autoBindedDictOfUINavigationControllerIDNNavBarHidden
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDictionaryKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDictionaryKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (BOOL)idn_controllerBasedNavBarHiddenEnabled
{
	NSMutableDictionary* dic = [self bindedDictOfUINavigationControllerIDNNavBarHidden];
	return [dic[@"idn_controllerBasedNavBarHiddenEnabled"] boolValue];
}

- (void)setIdn_controllerBasedNavBarHiddenEnabled:(BOOL)idn_controllerBasedNavBarHiddenEnabled
{
	NSMutableDictionary* dic = [self autoBindedDictOfUINavigationControllerIDNNavBarHidden];
	if([dic[@"idn_controllerBasedNavBarHiddenEnabled"] boolValue] == idn_controllerBasedNavBarHiddenEnabled)
		return;
	dic[@"idn_controllerBasedNavBarHiddenEnabled"] = @(idn_controllerBasedNavBarHiddenEnabled);
	if(idn_controllerBasedNavBarHiddenEnabled)
	{
		IDNNavBarHiddenPopGestureRecognizerDelegate *delegate = [[IDNNavBarHiddenPopGestureRecognizerDelegate alloc] init];
		delegate.navigationController = self;
		self.interactivePopGestureRecognizer.delegate = delegate;
		self.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
		dic[@"delegate"] = delegate;
	}
	else
	{
		[dic removeObjectForKey:@"delegate"];
		self.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
	}
}

@end

@implementation UIViewController (IDNNavBarHidden)

+ (void)load
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method oldMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
		Method newMethod = class_getInstanceMethod(self, @selector(idnNavBarHidden_viewWillAppear:));
		method_exchangeImplementations(oldMethod, newMethod);

		Method oldMethod2 = class_getInstanceMethod(self, @selector(viewDidLoad));
		Method newMethod2 = class_getInstanceMethod(self, @selector(IDNNavBarHidden_viewDidLoad));
		method_exchangeImplementations(oldMethod2, newMethod2);
	}
}

- (void)IDNNavBarHidden_viewDidLoad
{
	[self IDNNavBarHidden_viewDidLoad];
	if([self isKindOfClass:[UINavigationController class]])
		((UINavigationController*)self).idn_controllerBasedNavBarHiddenEnabled = YES;
}

- (void)idnNavBarHidden_viewWillAppear:(BOOL)animated
{
	[self idnNavBarHidden_viewWillAppear:animated];
	
	if(self.navigationController && self.navigationController.idn_controllerBasedNavBarHiddenEnabled && self.navigationController.navigationBarHidden!=self.idn_prefersNavigationBarHidden)
	{
		self.navigationController.navigationBarHidden = self.navigationController.navigationBarHidden; //清除内部异常状态。（有时UINavigationController会进入异常状态）
		[self.navigationController setNavigationBarHidden:self.idn_prefersNavigationBarHidden animated:animated];
	}
}

- (BOOL)idn_prefersNavigationBarHidden
{
	return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIdn_prefersNavigationBarHidden:(BOOL)hidden
{
	objc_setAssociatedObject(self, @selector(idn_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

