//
//  IDNViewControllerAnimatedTransitioningLeftRight.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

//从左弹入，向左弹出；或者从右弹入，向右弹出
@interface IDNViewControllerAnimatedTransitioningLeftRight : NSObject
<UIViewControllerAnimatedTransitioning>

@property(nonatomic) BOOL right; //为NO表示从左进，向左出；YES表示从右进，向右出
@property(nonatomic) BOOL reverse; //默认NO，表示从左弹入；为YES表示向左弹出

@end
