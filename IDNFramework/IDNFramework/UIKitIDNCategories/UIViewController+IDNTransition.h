//
//  UIViewController+IDNTransition.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController(IDNTransition)

- (void)presentViewControllerFromLeft:(UIViewController *)viewController completion:(void (^)(void))completion; //从左向右出现新界面。
- (void)presentViewControllerFromRight:(UIViewController *)viewController completion:(void (^)(void))completion; //从右向左出现新界面。

@end
