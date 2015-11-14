//
//  UIViewController+IDNPresentationStack.h
//
//  Created by mahj on 15/8/26.
//  Copyright (c) 2015年 shendou. All rights reserved.
//

#import <UIKit/UIKit.h>

// 呈现栈只是记录视图控制器的Present关系，不会强引用任何视图控制器
@interface UIViewController(IDNPresentationStack)

@property(nonatomic) BOOL enablePresentationStack; // 启用当前Controller的呈现栈
- (void)dismissViewControllersInPresentationStack; // dismiss呈现栈中在self之后呈现的所有视图控制器

+ (void)registerChildControllers:(NSArray*)childControllers forInPresentationStackController:(UIViewController*)controller;
+ (void)unregisterChildControllers:(NSArray*)childControllers forInPresentationStackController:(UIViewController*)controller;

@end
