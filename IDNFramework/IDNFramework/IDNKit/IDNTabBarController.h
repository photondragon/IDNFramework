//
//  IDNTabBarController.h
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDNTabBarController : UIViewController

+ (nonnull instancetype)sharedTabBarController;
+ (nonnull instancetype)recreateTabBarController;

@property(nonatomic,readonly,nonnull) UITabBar* tabBar;

@property(nullable, nonatomic,copy) NSArray<__kindof UIViewController *> *viewControllers;

@property(nullable, nonatomic, assign) __kindof UIViewController *selectedViewController;

@property(nonatomic) NSUInteger selectedIndex;

- (void)showTabBarInController:(nonnull UIViewController*)controller;

@end
