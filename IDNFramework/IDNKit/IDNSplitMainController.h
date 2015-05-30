//
//  IDNSplitMainController.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 主界面上下分开出现主菜单的Main控制器
@interface IDNSplitMainController : UIViewController

@property(nonatomic,strong,readonly) UINavigationController* mainController; //主界面。是一个导航控制器
@property(nonatomic,strong) UIViewController* menuController; //菜单Controller

@property(nonatomic,readonly) BOOL isShowingMenuController; //是否正在显示菜单Controller

- (void)showMenuController:(BOOL)showMenu; //设置是否显示menuController。有动画效果

@property(nonatomic) CGFloat menuBottomMargin; //菜单底边距（距离屏幕底部的距离）

@end
