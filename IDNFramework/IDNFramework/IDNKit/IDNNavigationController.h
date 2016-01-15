//
//  IDNNavigationController.h
//  IDNFramework
//
//  Created by photondragon on 28/12/15.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  IDNNavigationController.topViewController只要实现UIGestureRecognizerDelegate协议的两个方法：
 *  - (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
 *  - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
 *  就可以控制手势返回是否有效。
 */
@interface IDNNavigationController : UINavigationController

@end
