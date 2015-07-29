//
//  IDNActivityIndicator.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 功能同UIActivityIndicator，显示一个旋转的半圆环（有模糊的阴影）。
@interface IDNActivityIndicator : UIButton

@property (nonatomic, assign) CGFloat lineWidth; //默认3.0
@property (nonatomic, strong) UIColor *color; //默认是一种蓝色
@property (nonatomic, readonly) BOOL isAnimating;
@property(nonatomic) BOOL hidesWhenStopped;

- (void)startAnimating;
- (void)stopAnimating;

@end
