//
//  UIImage+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/5/9.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(IDNExtend)

- (UIImage *)resizedImageWithSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFitSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size clipToBounds:(BOOL)clipToBounds;
- (UIImage *)imageWithoutOrientation;

/**
 *  裁剪图像
 *
 *  @param clipRect 图像中要裁剪部分的坐标（图像左上角为原点）。如果坐标值不是1的整数倍，会四舍五入
 *  @param maxSize  裁剪后缩放的最大尺寸。如果设为CGSizeZero，表示没有限制，不缩放。
 *
 *  @return 返回裁剪后的图像
 */
- (UIImage*)clipedImageWithClipRect:(CGRect)clipRect maxSize:(CGSize)maxSize;

@end
