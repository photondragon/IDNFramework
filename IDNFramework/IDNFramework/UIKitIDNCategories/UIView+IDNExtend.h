//
//  UIView+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(IDNExtend)

- (UIResponder*)findFirstResponder;

@property(nonatomic) CGFloat cornerRadius;
@property(nonatomic) CGFloat borderWidth;
@property(nonatomic,strong) UIColor* borderColor;

@end
