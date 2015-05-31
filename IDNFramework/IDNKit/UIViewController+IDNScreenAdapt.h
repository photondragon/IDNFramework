//
//  UIViewController+IDNScreenAdapt.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScreen+IDNExtend.h"

@interface UIViewController(IDNScreenAdapt)

/*
 假设类名是MyViewController，当在5.5寸设备上调用此方法，
 并且存在MyViewController-iPhone55.xib文件时，函数返回@"MyViewController-iPhone55"
 不存在MyViewController-iPhone55.xib文件时，函数返回@"MyViewController"
 */
+ (NSString*)autoNibName; //根据设备尺寸自动选择对应的nib文件。

@end

@interface UIView(IDNScreenAdapt)

+ (NSString*)autoNibName;

@end