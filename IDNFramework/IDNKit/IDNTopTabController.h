//
//  IDNScanCodeView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 要与NavigationController配合使用（作为其子Controller）。
@interface IDNTopTabController : UIViewController

@property(nonatomic,copy) NSArray* pageControllers;
@property(nonatomic) NSInteger selectedTabIndex;//-1表示没选中任何Tab。如果设置了pageControllers，但没有设置selectedIndex，在Controller willAppear时，将自动设置self.selectedIndex = 0;

@end

@interface UIViewController(IDNTopTabController)

@property(nonatomic,strong) UIButton* topTabBarLeftButton;//显示在TopTabbar的左边的按钮
@property(nonatomic,strong) UIButton* topTabBarRightButton;//显示在TopTabbar的右边的按钮
@property(nonatomic,readonly,weak) IDNTopTabController *topTabController;

@end