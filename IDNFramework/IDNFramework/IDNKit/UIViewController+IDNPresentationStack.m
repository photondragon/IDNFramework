//
//  UIViewController+IDNPresentationStack.m
//
//  Created by mahj on 15/8/26.
//

#import "UIViewController+IDNPresentationStack.h"
#import <objc/runtime.h>
#import "NSObject+IDNDeallocBlock.h"
#import "NSPointerArray+IDNExtend.h"

//正在Presenting的视图控制器的信息
@interface IDNPresentingVCInfo : NSObject
@property(nonatomic,weak) UIViewController* controller;
@property(nonatomic,strong) NSPointerArray* childControllers; // vc的子视图控制器
@end
@implementation IDNPresentingVCInfo
{
	__unsafe_unretained UIViewController* uuController; // 如果在self.controller的deallocBlock中检测，self.controller属性返回nil，因为其是weak型，所以这里还需要__unsafe_unretained型变量保存self.controller的地址
}
- (BOOL)isEqualToController:(UIViewController*)controller
{
	return uuController == controller;
}
- (void)setController:(UIViewController *)controller
{
	_childControllers = nil;
	_controller = controller;
	uuController = controller;
	if(controller)
	{
		if([controller isKindOfClass:[UINavigationController class]])
		{
			for (UIViewController* child in ((UINavigationController*)controller).viewControllers) {
				[self.childControllers addPointer:(void*)child];
			}
		}
		else if([controller isKindOfClass:[UITabBarController class]])
		{
			for (UIViewController* child in ((UITabBarController*)controller).viewControllers) {
				[self.childControllers addPointer:(void*)child];
			}
		}
	}
}
- (NSPointerArray*)childControllers
{
	if(_childControllers==nil)
	{
		_childControllers = [NSPointerArray weakObjectsPointerArray];
	}
	return _childControllers;
}
@end

@implementation UIViewController(IDNPresentationStack)

+ (void)load
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method method1 = class_getInstanceMethod(self, @selector(presentViewController:animated:completion:));
		Method method2 = class_getInstanceMethod(self, @selector(presentAndLogViewController:animated:completion:));
		method_exchangeImplementations(method1, method2);

		Method method3 = class_getInstanceMethod(self, @selector(dismissViewControllerAnimated:completion:));
		Method method4 = class_getInstanceMethod(self, @selector(dismissAndLogViewControllerAnimated:completion:));
		method_exchangeImplementations(method3, method4);
	}
}

- (void)presentAndLogViewController:(UIViewController *)controller animated:(BOOL)flag completion:(void (^)(void))completion
{
	[self presentAndLogViewController:controller animated:flag completion:completion];
	
	if(controller==nil)
		return;
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		IDNPresentingVCInfo* info = stack[stack.count-1]; //取栈的最后一个
		if(info.controller == self || [info.childControllers containsPointer:(void*)self])
		{
			IDNPresentingVCInfo* newInfo = [[IDNPresentingVCInfo alloc] init];
			newInfo.controller = controller;
			[stack addObject:newInfo];
			
			__unsafe_unretained __typeof(self) uucontroller = controller;
			[controller addDeallocBlock:^{
				NSMutableArray* stacks = [UIViewController idnPresentationStacks];
				for (NSMutableArray* stack in stacks) {
					for (NSInteger i=1; i<stack.count; i++) // 第0个不检测，因为它是在setEnablePresentationStack:中设置的deallocBlock中检测并移除的
					{
						IDNPresentingVCInfo* info = stack[i];
						if([info isEqualToController:uucontroller])
						{
							[stack removeObjectsInRange:NSMakeRange(i, stack.count-i)];
							break;
						}
					}
				}
			}];

			break;
		}
	}
}

- (void)dismissAndLogViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
	[self dismissAndLogViewControllerAnimated:flag completion:completion];
	
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		IDNPresentingVCInfo* info = stack[stack.count-1]; //取栈的最后一个
		if(info.controller == self)
		{
			[stack removeObjectAtIndex:stack.count-1];
			break;
		}
	}
}

- (void)dismissViewControllersInPresentationStack
{
	NSArray* dismissControllers = nil;
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		for (NSInteger i=0; i<stack.count; i++) {
			IDNPresentingVCInfo* info = stack[i];
			if(info.controller==self || [info.childControllers containsPointer:(void*)self])
			{
				dismissControllers = [stack subarrayWithRange:NSMakeRange(i+1, stack.count-i-1)];
				break;
			}
		}
	}
	for (NSInteger i = dismissControllers.count-1; i>=0; i--) {
		IDNPresentingVCInfo* info = dismissControllers[i];
		[info.controller dismissViewControllerAnimated:NO completion:nil];
	}
}

+ (NSMutableArray*)idnPresentationStacks
{
	static NSMutableArray* presentationStacks = nil;
	if(presentationStacks==nil)
	{
		presentationStacks = [NSMutableArray new];
	}
	return presentationStacks;
}

- (BOOL)enablePresentationStack
{
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		IDNPresentingVCInfo* info = stack[0];
		if(info.controller == self) // 已启用
			return YES;
	}
	return NO;
}

- (void)setEnablePresentationStack:(BOOL)enablePresentationStack
{
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	if(enablePresentationStack)
	{
		for (NSMutableArray* stack in stacks) {
			IDNPresentingVCInfo* info = stack[0];
			if(info.controller == self) // 已启用
				return;
		}
		IDNPresentingVCInfo* info = [[IDNPresentingVCInfo alloc] init];
		info.controller = self;
		[stacks addObject:[NSMutableArray arrayWithObject:info]];
		
		__unsafe_unretained __typeof(self) uuself = self;
		[self addDeallocBlock:^{
			uuself.enablePresentationStack = NO;
		}];
	}
	else
	{
		// 只禁用presentation stack，不dissmissViewController
		for (NSInteger i=0;i<stacks.count;i++) {
			NSMutableArray* stack = stacks[i];
			IDNPresentingVCInfo* info = stack[0];
//			if(info.controller == self) // 这里info.controller返回的是nil，因为其是weak属性
			if([info isEqualToController:self])
			{
				[stacks removeObjectAtIndex:i];
				return;
			}
		}
	}
}

+ (void)registerChildControllers:(NSArray*)childControllers forInPresentationStackController:(UIViewController*)controller
{
	if(childControllers.count==0 || controller==nil)
		return;
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		for (NSInteger i=0; i<stack.count; i++) {
			IDNPresentingVCInfo* info = stack[i];
			if(info.controller==controller)
			{
				for (UIViewController* childController in childControllers) {
					if([info.childControllers containsPointer:(void*)childController]==NO)
					{
						[info.childControllers addPointer:(void*)childController];
						[info.childControllers compact];
					}
				}
				break;
			}
		}
	}
}

+ (void)unregisterChildControllers:(NSArray*)childControllers forInPresentationStackController:(UIViewController*)controller
{
	if(childControllers.count==0 || controller==nil)
		return;
	NSMutableArray* stacks = [UIViewController idnPresentationStacks];
	for (NSMutableArray* stack in stacks) {
		for (NSInteger i=0; i<stack.count; i++) {
			IDNPresentingVCInfo* info = stack[i];
			if(info.controller==controller)
			{
				for (UIViewController* childController in childControllers) {
					[info.childControllers removePointerIdentically:(void*)childController];
				}
				break;
			}
		}
	}
}

@end

@interface UINavigationController(IDNPresentationStack)

@end

@implementation UINavigationController(IDNPresentationStack)

+ (void)load
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method oldMethod1 = class_getInstanceMethod(self, @selector(initWithRootViewController:));
		Method newMethod1 = class_getInstanceMethod(self, @selector(initAndLogWithRootViewController:));
		method_exchangeImplementations(oldMethod1, newMethod1);

		Method oldMethod2 = class_getInstanceMethod(self, @selector(pushViewController:animated:));
		Method newMethod2 = class_getInstanceMethod(self, @selector(pushAndLogViewController:animated:));
		method_exchangeImplementations(oldMethod2, newMethod2);

		Method oldMethod3 = class_getInstanceMethod(self, @selector(setViewControllers:animated:));
		Method newMethod3 = class_getInstanceMethod(self, @selector(setAndLogViewControllers:animated:));
		method_exchangeImplementations(oldMethod3, newMethod3);
		
		Method oldMethod4 = class_getInstanceMethod(self, @selector(popToViewController:animated:));
		Method newMethod4 = class_getInstanceMethod(self, @selector(popAndLogToViewController:animated:));
		method_exchangeImplementations(oldMethod4, newMethod4);
		
		Method oldMethod5 = class_getInstanceMethod(self, @selector(popToRootViewControllerAnimated:));
		Method newMethod5 = class_getInstanceMethod(self, @selector(popAndLogToRootViewControllerAnimated:));
		method_exchangeImplementations(oldMethod5, newMethod5);
		
		Method oldMethod6 = class_getInstanceMethod(self, @selector(popViewControllerAnimated:));
		Method newMethod6 = class_getInstanceMethod(self, @selector(popAndLogViewControllerAnimated:));
		method_exchangeImplementations(oldMethod6, newMethod6);
	}
}

- (instancetype)initAndLogWithRootViewController:(UIViewController *)rootViewController
{
	[UIViewController registerChildControllers:@[rootViewController] forInPresentationStackController:self];
	return [self initAndLogWithRootViewController:rootViewController];
}

- (void)pushAndLogViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	[UIViewController registerChildControllers:@[viewController] forInPresentationStackController:self];
	[self pushAndLogViewController:viewController animated:animated];
}

- (void)setAndLogViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
	[UIViewController unregisterChildControllers:self.viewControllers forInPresentationStackController:self];
	[UIViewController registerChildControllers:viewControllers forInPresentationStackController:self];
	[self setAndLogViewControllers:viewControllers animated:animated];
}

- (NSArray *)popAndLogToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	NSInteger index = [self.viewControllers indexOfObjectIdenticalTo:viewController];
	NSInteger count = self.viewControllers.count;
	if(index>=0 && index<count-1)
	{
		[UIViewController unregisterChildControllers:[self.viewControllers subarrayWithRange:NSMakeRange(index+1, count-index-1)] forInPresentationStackController:self];
	}
	return [self popAndLogToViewController:viewController animated:animated];
}

- (NSArray *)popAndLogToRootViewControllerAnimated:(BOOL)animated
{
	NSInteger count = self.viewControllers.count;
	if(count>=2)
		[UIViewController unregisterChildControllers:[self.viewControllers subarrayWithRange:NSMakeRange(1, count-1)] forInPresentationStackController:self];
	return [self popAndLogToRootViewControllerAnimated:animated];
}

- (UIViewController*)popAndLogViewControllerAnimated:(BOOL)animated
{
	NSInteger count = self.viewControllers.count;
	if(count>0)
		[UIViewController unregisterChildControllers:@[[self.viewControllers lastObject]] forInPresentationStackController:self];
	return [self popAndLogViewControllerAnimated:animated];
}

@end

@interface UITabBarController(IDNPresentationStack)

@end

@implementation UITabBarController(IDNPresentationStack)

+ (void)load
{
	static BOOL exchanged = NO;
	if(exchanged==NO)
	{
		exchanged = YES;
		Method oldMethod = class_getInstanceMethod(self, @selector(setViewControllers:animated:));
		Method newMethod = class_getInstanceMethod(self, @selector(setAndLogViewControllers:animated:));
		method_exchangeImplementations(oldMethod, newMethod);
	}
}

- (void)setAndLogViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
	[UIViewController unregisterChildControllers:self.viewControllers forInPresentationStackController:self];
	[UIViewController registerChildControllers:viewControllers forInPresentationStackController:self];
	[self setAndLogViewControllers:viewControllers animated:animated];
}

@end