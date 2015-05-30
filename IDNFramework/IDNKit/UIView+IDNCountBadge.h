//
//  UIView+IDNCountBadge.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 在视图的右上角显示数字标牌（红底+白色数字）。
@interface UIView(IDNCountBadge)

@property(nonatomic) NSInteger countInBadge;

@property(nonatomic,strong) UIColor* badgeColor;
@property(nonatomic,strong) UIFont* badgeFont;

@end
