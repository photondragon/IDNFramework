//
//  UIImage+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/9.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(IDNExtend)

- (UIImage *)resizedImageWithSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFitSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size;
- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size clipToBounds:(BOOL)clipToBounds;
- (UIImage *)imageWithoutOrientation;

+ (CGSize)aspectFitSizeWithSize:(CGSize)size originSize:(CGSize)originSize;
+ (CGSize)aspectFillSizeWithSize:(CGSize)size originSize:(CGSize)originSize;

/**
 *  裁剪图像
 *
 *  @param clipRect 图像中要裁剪部分的坐标（图像左上角为原点）。如果坐标值不是1的整数倍，会四舍五入
 *  @param maxSize  裁剪后缩放的最大尺寸。如果设为CGSizeZero，表示没有限制，不缩放。
 *
 *  @return 返回裁剪后的图像
 */
- (UIImage*)clipedImageWithClipRect:(CGRect)clipRect maxSize:(CGSize)maxSize;

#pragma mark - 在内存中生成图像

+ (UIImage*)commonImageGoBack; //返回按钮的图像，40x40。一般用于导航栏的返回按钮
+ (UIImage*)backgroudImageWithColor:(UIColor*)bgColor; //生成1x1的纯色背景图片
+ (UIImage*)imageWithSize:(CGSize)size color:(UIColor*)bgColor; //生成一张指定大小的纯色图片
@end
