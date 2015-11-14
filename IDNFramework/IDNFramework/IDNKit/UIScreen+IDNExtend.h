//
//  UIScreen+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _ScreenSizeType{
	IDNScreenSizeTypeUnknown=0,
	IDNScreenSizeType35, //3.5寸
	IDNScreenSizeType40, //4.0寸
	IDNScreenSizeType47, //4.7寸
	IDNScreenSizeType55, //5.5寸
}IDNScreenSizeType;

@interface UIScreen(IDNExtend)

+ (CGFloat)pixelWidth; //一个像素宽度
+ (IDNScreenSizeType)mainScreenSizeType;

@end
