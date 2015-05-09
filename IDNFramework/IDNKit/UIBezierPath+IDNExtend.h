//
//  UIBezierPath+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 ios dev net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath(IDNExtend)

//添加多边形。points为多边形的所有点的坐标，count为点的个数
- (void)addPolygonWithPoints:(CGPoint*)points count:(int)count;
- (void)addRect:(CGRect)rect;
- (void)addRoundedRect:(CGRect)rect cornorRadius:(CGFloat)cornorRadius;

@end
