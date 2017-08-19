//
//  UIWindow+IDNExt.h
//  IDNFramework
//
//  Created by photondragon on 15/11/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

#define WindowCustomViewTag 4866522 //tag属性等于这个值的子view，可以被removeAllCustomViews方法移除

@interface UIWindow(IDNExt)

//+ (UIWindow*)keyWindow; // UIWindow 已经有这个方法了，不过是私有方法
+ (UIWindow*)mainWindow; // 同keyWindow
+ (UIViewController*)rootViewController;
+ (UIViewController*)presentedViewController;

- (void)addCustomSubview:(UIView*)customView; // 同addSubview:，只是添加的customView.tag会被设置为WindowCustomViewTag
- (void)removeAllCustomViews; // 删除所有tag值等于WindowCustomViewTag的子view（不删除孙子view）

@end
