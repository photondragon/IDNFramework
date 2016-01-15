//
//  IDNMainController.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 主菜单从左侧滑出的Main控制器
@interface IDNMainController : UIViewController

@property(nonatomic,strong,readonly) UINavigationController* mainController; //主界面。是一个导航控制器
@property(nonatomic,strong) UIViewController* sideController; //左侧界面，一般设置为菜单

@property(nonatomic,strong,readonly) UIPanGestureRecognizer* panGestureRecognizer; //控制菜单显示的手势

@property(nonatomic,readonly) BOOL isShowingSideController; //是否正在显示左侧Controller

- (void)showSideController:(BOOL)showSide; //设置是否显示SideController。有动画效果

@end
