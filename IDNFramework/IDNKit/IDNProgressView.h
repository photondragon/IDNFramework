//
//  IDNProgressView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IDNProgressViewStyle) {
	IDNProgressViewStyleDefault, // 等于Cake
	IDNProgressViewStyleCake, // 饼状
	IDNProgressViewStyleCircle, // 圆环
};

@interface IDNProgressView : UIView

- (instancetype)initWithProgressViewStyle:(IDNProgressViewStyle)style;

@property(nonatomic) IDNProgressViewStyle progressViewStyle; // 默认为IDNProgressViewStyleDefault
@property(nonatomic) float progress; // 进度，[0.0, 1.0]之间, 默认0.0。超过范围的自动调整到范围以内
@property(nonatomic, retain) UIColor* progressTintColor; //已完成进度的颜色。默认RGBA(21,138,228,255)
@property(nonatomic, retain) UIColor* trackTintColor; //未完成进度的颜色。默认[UIColor lightGrayColor]。对StyleCake无用

@property(nonatomic) CGFloat lineWidth; //线宽。可以为0，小于0自动变为0，默认1.0。

@end
