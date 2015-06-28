//
//  UIView+IDNZoom.h
//  IDNFramework
//
//  Created by photondragon on 15/6/29.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView(IDNZoom)

@property(nonatomic) CGFloat zoomRatio; //等比缩放因子。1.0表示不缩放

- (void)setZoomRatio:(CGFloat)ratio recursive:(BOOL)recursive; //recursive表示是否递归。自动忽略TableView/UISwitch的所有子View
- (void)setZoomRatio:(CGFloat)ratio recursive:(BOOL)recursive ignoreViews:(NSArray*)ignoreViews; //recursive表示是否递归，在ignoreViews中列出的view不会被缩放

- (void)zoomSubviewsWithRatio:(CGFloat)ratio;//缩放所有subview 非递归 subview的subview让其自行管理
- (void)zoomSubviewsWithRatio:(CGFloat)ratio recursive:(BOOL)recursive;
- (void)zoomSubviewsWithRatio:(CGFloat)ratio recursive:(BOOL)recursive ignoreViews:(NSArray*)ignoreViews;

@end
