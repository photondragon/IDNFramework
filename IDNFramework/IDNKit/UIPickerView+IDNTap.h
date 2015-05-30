//
//  UIPickerView+IDNTap.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIPickerView(IDNTap)
<UIGestureRecognizerDelegate>

@property(nonatomic,strong) void (^currentRowTappedBlock)(UIPickerView* picker, NSUInteger component);//设置当点击当前选中行时执行的Block。设置了这个属性后，点击当前行也会触发row did select委托方法

@end
