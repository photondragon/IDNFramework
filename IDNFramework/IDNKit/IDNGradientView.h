//
//  IDNGradientView.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

//渐变色视图。从上到下画渐变色。
@interface IDNGradientView : UIView

@property(nonatomic,strong) NSArray* gradientColors; //设置渐变色。最多256个；最少2个。

- (void)setGradientColors:(NSArray *)gradientColors locations:(CGFloat[])locations; //示例：[gradientView setGradientColors:@[color1, color2, color3] locations:{0.0, 0.6, 1.0}];

@end
