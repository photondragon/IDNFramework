//
//  UIButton+IDNColor.h
//  IDNFramework
//
//  Created by mahj on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton(IDNColor)

@property(nonatomic,strong) UIColor* backgroundColorHighlighted; //按下时的背景色. 默认为nil
@property(nonatomic,strong) UIColor* backgroundColorDisabled; //禁用时的背景色. 默认为nil

@end
