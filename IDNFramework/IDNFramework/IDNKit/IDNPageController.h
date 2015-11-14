//
//  IDNPageController.h
//  IDNPageController
//
//  Created by photondragon on 15/7/4.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IDNPageControllerDelegate;

/**
 类似UITabBarController的页面切换控件，只是TabBar在顶部
 */
@interface IDNPageController : UIViewController

@property(nonatomic,copy) NSArray *viewControllers; ///< viewController.title会作为标题显示在topBar上。

@property(nonatomic,weak) id<IDNPageControllerDelegate> delegate;

@property(nonatomic) NSInteger selectedIndex; // 暂不支持kvo

#pragma mark 外观设置

@property(nonatomic,strong) UIFont* titleFont; //默认为系统字体，字号15
@property(nonatomic,strong) UIColor* titleColor; //默认[UIColor colorWithWhite:0.2 alpha:1.0];
@property(nonatomic,strong) UIColor* titleBarColor; //默认[UIColor colorWithWhite:0.9 alpha:1.0]
@property(nonatomic,strong) UIColor* selectedColor; //默认RGBA(27,159,224,255)
@property(nonatomic,strong) UIColor* selectedTitleColor; //默认[UIColor colorWithWhite:0.2 alpha:1.0]，表示与titleColor相同

@property(nonatomic) BOOL isTitleBarOnBottom; //标题栏是否在底部

@end

@protocol IDNPageControllerDelegate <NSObject>

- (void)pageController:(IDNPageController*)pageController didSelectViewControllerAtIndex:(NSInteger)index;

@end

@interface UIViewController(IDNPageController)

@property(nonatomic,weak,readonly) IDNPageController* idnPageController;

@end
