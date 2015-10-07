//
//  UIView+IDNKeyboard.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(IDNKeyboard)

@property(nonatomic,strong) void (^keyboardFrameWillChangeBlock)(CGFloat bottomDistance, double animationDuration, UIViewAnimationCurve animationCurve); ///< 当键盘Frame改变时此Block被调用。bottomDistance是键盘顶部与self视图底部的距离；animationDuration是键盘动画持续时间
@property(nonatomic) BOOL autoResignFirstResponder; ///< 当此属性设为YES时，当点击到当前view或其子孙view，并且点到的view不是id<UITextInput>类型时，自动取消子孙view的firstResponder

@end
