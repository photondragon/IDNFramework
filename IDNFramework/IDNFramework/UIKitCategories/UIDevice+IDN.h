//
//  UIDevice+IDN.h
//  IDNFramework
//
//  Created by photondragon on 16/1/12.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice(IDN)

- (void)idn_setOrientation:(UIInterfaceOrientation)orientation;

#pragma mark - 系统音量

+ (CGFloat)volume;
+ (void)setVolume:(CGFloat)volume;
+ (void)changeVolume:(CGFloat)deltaVolume;

@end
