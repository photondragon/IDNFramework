//
//  IDNSearchBar.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDNSearchBar : UISearchBar

@property (nonatomic,weak) UIScrollView* containerView;//当设置这个属性时，如果是普通scrollView刷新控件就会成为其子View；如果是tableView，则会成为tableView的tableHeaderView。

- (void)autoHideNavBarOfController:(UIViewController*)controller; //当搜索时，如果controller是UINavigationController，则自动隐藏其导航条；如果controller是普通UIViewController，则自动隐藏它所在的NavigationController的导航条

@end
