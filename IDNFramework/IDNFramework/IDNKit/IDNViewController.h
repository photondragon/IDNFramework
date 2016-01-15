//
//  IDNViewController.h
//  IDNFramework
//
//  Created by photondragon on 15/10/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDNViewController : UIViewController

@property(nonatomic,strong,readonly) UINavigationItem *idn_navigationItem;

@property(nonatomic,strong,readonly) UINavigationBar* idn_navigationBar;
@property(nonatomic,strong,readonly) UIView* idn_statusBar;

@property(nonatomic,strong,readonly) UIView* idn_topBar; //包含idn_statusBar和idn_navigationBar
@property(nonatomic,strong,readonly) UIView* idn_contentView; //不与导航条重叠，首次调用时创建（延迟加载）。

- (void)hideTopBar;
- (void)bringTopBarToFront;

- (void)addGoBackButton; //添加返回按钮
- (void)delGoBackButton; //删除返回按钮
- (void)popBackViewController:(id)sender; //返回按钮会调用这个方法（内部会popViewController)。你也可以手动调用这个方法；子类也重载这个方法，实现有条件的popViewController

- (void)addCloseButton; //在导航条左边加一个“关闭”按钮。一般在presented nav controller的子controller中使用
- (void)delCloseButton;

@end
