//
//  IDNViewControllerAnimatedTransitioningLeftRight.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

//从左弹入，向左弹出
@interface IDNViewControllerAnimatedTransitioningLeftRight : NSObject
<UIViewControllerAnimatedTransitioning>

@property(nonatomic) BOOL reverse; //默认NO，表示从左弹入；为YES表示向左弹出

@end
