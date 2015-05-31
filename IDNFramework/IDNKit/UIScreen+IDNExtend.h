//
//  UIScreen+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _ScreenSizeType{
	ScreenSizeTypeUnknown=0,
	ScreenSizeType35, //3.5寸
	ScreenSizeType40, //4.0寸
	ScreenSizeType47, //4.7寸
	ScreenSizeType55, //5.5寸
}ScreenSizeType;

@interface UIScreen(IDNExtend)

+ (CGFloat)pixelWidth; //一个像素宽度
+ (ScreenSizeType)mainScreenSizeType;

@end
