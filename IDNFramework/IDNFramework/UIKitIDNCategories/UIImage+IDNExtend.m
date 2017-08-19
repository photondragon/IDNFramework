//
//  UIImage+IDNExtend.m
//  IDNFramework
//
//  Created by photondragon on 15/5/9.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIImage+IDNExtend.h"

@implementation UIImage(IDNExtend)

- (UIImage *)imageWithoutOrientation
{
	CGSize size = self.size; //size after rotation
	CGSize sizeInPixels; //size in pixels after rotation
	CGFloat scale = self.scale;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;

	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

	CGColorSpaceRelease(colorSpace);

	UIImageOrientation orientation = self.imageOrientation;
	CGImageRef imageRef = self.CGImage;
	CGSize originalSize = {CGImageGetWidth(imageRef),CGImageGetHeight(imageRef)};//size in pixels before rotation

	// rotate
	switch (orientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			CGContextRotateCTM(context, M_PI/2);
			CGContextTranslateCTM(context, 0, -originalSize.height);
			break;
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			CGContextRotateCTM(context, -M_PI/2);
			CGContextTranslateCTM(context, -originalSize.width, 0);
			break;
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			CGContextRotateCTM(context, M_PI);
			CGContextTranslateCTM(context, -originalSize.width, -originalSize.height);
			break;
		default:
			break;
	}

	// flip
	if(orientation==UIImageOrientationLeftMirrored ||
	   orientation==UIImageOrientationRightMirrored ||
	   orientation==UIImageOrientationUpMirrored ||
	   orientation==UIImageOrientationDownMirrored)
		CGContextConcatCTM(context, CGAffineTransformMake(-1, 0, 0, 1, originalSize.width, 0));

	CGContextDrawImage(context, CGRectMake(0, 0, originalSize.width, originalSize.height), imageRef);

	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:0];
	CGImageRelease(imgRef);

	return img;
}

- (UIImage *)resizedImageWithSize:(CGSize)size
{
	size.width	= (int)size.width;//取整
	size.height	= (int)size.height;//取整

	CGFloat scale = self.scale;

	CGSize sizeInPixels;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;

	UIImageOrientation orientation = self.imageOrientation;
	if(orientation==UIImageOrientationLeft ||
	   orientation==UIImageOrientationLeftMirrored ||
	   orientation==UIImageOrientationRight ||
	   orientation==UIImageOrientationRightMirrored)
	{
		CGFloat f = sizeInPixels.width;
		sizeInPixels.width = sizeInPixels.height;
		sizeInPixels.height = f;
	}

	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

	CGColorSpaceRelease(colorSpace);
	CGImageRef imageRef = self.CGImage;
	CGContextDrawImage(context, CGRectMake(0, 0, sizeInPixels.width, sizeInPixels.height), imageRef);

	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:self.imageOrientation];
	CGImageRelease(imgRef);

	return img;
}

+ (CGSize)aspectFitSizeWithSize:(CGSize)size originSize:(CGSize)originSize
{
	if(size.width<=0 || size.height<=0)
		return CGSizeZero;
	CGFloat wRatio = size.width/originSize.width;
	CGFloat hRatio = size.height/originSize.height;
	CGFloat ratio = wRatio<hRatio ? wRatio : hRatio;
	CGSize newSize = CGSizeMake((int)(originSize.width*ratio), (int)(originSize.height*ratio));
	return newSize;
}

+ (CGSize)aspectFillSizeWithSize:(CGSize)size originSize:(CGSize)originSize
{
	if(size.width<=0 || size.height<=0)
		return CGSizeZero;
	CGFloat wRatio = size.width/originSize.width;
	CGFloat hRatio = size.height/originSize.height;
	CGFloat ratio = wRatio>hRatio ? wRatio : hRatio;
	CGSize nonClipSize = CGSizeMake((int)(originSize.width*ratio), (int)(originSize.height*ratio));
	return nonClipSize;
}

- (UIImage *)resizedImageWithAspectFitSize:(CGSize)size
{
	if(size.width<=0 || size.height<=0)
		return nil;
	CGSize newSize = [UIImage aspectFitSizeWithSize:size originSize:self.size];
	return [self resizedImageWithSize:newSize];
}

- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size
{
	return [self resizedImageWithAspectFillSize:size clipToBounds:NO];
}
- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size clipToBounds:(BOOL)clipToBounds;
{
	if(size.width<=0 || size.height<=0)
		return nil;
	CGSize nonClipSize = [UIImage aspectFillSizeWithSize:size originSize:self.size];
	if(clipToBounds==NO)
	{
		return [self resizedImageWithSize:nonClipSize];
	}
	else
	{
		size.width	= (int)size.width;//取整
		size.height	= (int)size.height;//取整
		
		CGFloat scale = self.scale;
		
		CGSize sizeInPixels;
		sizeInPixels.width = size.width*scale;
		sizeInPixels.height = size.height*scale;
		CGSize nonClipSizeInPixels;
		nonClipSizeInPixels.width = nonClipSize.width*scale;
		nonClipSizeInPixels.height = nonClipSize.height*scale;
		
		UIImageOrientation orientation = self.imageOrientation;
		if(orientation==UIImageOrientationLeft ||
		   orientation==UIImageOrientationLeftMirrored ||
		   orientation==UIImageOrientationRight ||
		   orientation==UIImageOrientationRightMirrored)
		{
			CGFloat f = sizeInPixels.width;
			sizeInPixels.width = sizeInPixels.height;
			sizeInPixels.height = f;
			f = nonClipSizeInPixels.width;
			nonClipSizeInPixels.width = nonClipSizeInPixels.height;
			nonClipSizeInPixels.height = f;
		}
		
		int bytesPerRow	= 4*sizeInPixels.width;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL,
													 sizeInPixels.width,
													 sizeInPixels.height,
													 8,
													 bytesPerRow,
													 colorSpace,
													 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
		
		CGColorSpaceRelease(colorSpace);
		CGImageRef imageRef = self.CGImage;
		CGContextDrawImage(context, CGRectMake((sizeInPixels.width-nonClipSizeInPixels.width)/2.0, (sizeInPixels.height-nonClipSizeInPixels.height)/2.0, nonClipSizeInPixels.width, nonClipSizeInPixels.height), imageRef);
		
		CGImageRef imgRef = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
		UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:self.imageOrientation];
		CGImageRelease(imgRef);
		
		return img;
	}
}

- (UIImage*)clipedImageWithClipRect:(CGRect)clipRect maxSize:(CGSize)maxSize
{
	CGSize originSize = self.size;
	
	// 校正裁剪区
	clipRect.origin.y = originSize.height - clipRect.origin.y - clipRect.size.height; //转为BMP坐标系（图像左下角为原点）
	clipRect.origin.x = roundf(clipRect.origin.x);
	clipRect.origin.y = roundf(clipRect.origin.y);
	clipRect.size.width = roundf(clipRect.size.width);
	clipRect.size.height = roundf(clipRect.size.height);
	if(clipRect.size.width > originSize.width-clipRect.origin.x)
		clipRect.size.width = originSize.width-clipRect.origin.x;
	if(clipRect.size.height > originSize.height-clipRect.origin.y)
		clipRect.size.height = originSize.height-clipRect.origin.y;
	if(clipRect.origin.x<0)
		clipRect.origin.x = 0;
	if(clipRect.origin.y<0)
		clipRect.origin.y = 0;
	
	CGSize size = clipRect.size;
	
	CGFloat scale = self.scale;
		
	CGSize sizeInPixels;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;
	
	UIImageOrientation orientation = self.imageOrientation;
	if(orientation==UIImageOrientationLeft ||
	   orientation==UIImageOrientationLeftMirrored ||
	   orientation==UIImageOrientationRight ||
	   orientation==UIImageOrientationRightMirrored)
	{
		CGFloat f = sizeInPixels.width;
		sizeInPixels.width = sizeInPixels.height;
		sizeInPixels.height = f;
	}
	
	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	
	CGColorSpaceRelease(colorSpace);
	CGContextDrawImage(context, CGRectMake(-clipRect.origin.x*scale, -clipRect.origin.y*scale, originSize.width*scale, originSize.height*scale), self.CGImage);
	
	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:self.imageOrientation];
	CGImageRelease(imgRef);
	
	if(maxSize.width>0 && maxSize.height>0) // 有最大限制
	{
		CGSize newSize = img.size;
		if (newSize.width>maxSize.width || newSize.height>maxSize.height) {
			return [img resizedImageWithAspectFitSize:maxSize];
		}
	}
	
	return img;
}

#pragma mark - 常用图像

+ (UIImage*)commonImageGoBack
{
	static UIImage* commonImageGoBack = nil;
	if(commonImageGoBack==nil)
		commonImageGoBack = [self createCommonImageGoBack];
	return commonImageGoBack;
}
+ (UIImage*)createCommonImageGoBack
{
	CGSize size = CGSizeMake(32, 32);
	CGSize sizeInPixels;
	CGFloat scale = [UIScreen mainScreen].scale;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;

	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

	CGColorSpaceRelease(colorSpace);

//	CGFloat redComponets[4] = {1.0f,0,0,1.0f};
//	CGContextSetStrokeColor(context, redComponets);
//	CGContextFillRect(context, CGRectMake(0, 0, sizeInPixels.width, sizeInPixels.height));
//
	CGFloat lineWith = 2*scale;
	CGContextSetLineWidth(context, lineWith);
	CGFloat whiteComponets[4] = {1.0f,1.0f,1.0f,1.0f};
	CGContextSetStrokeColor(context, whiteComponets);
	CGContextMoveToPoint(context, sizeInPixels.width*0.625f, sizeInPixels.height*0.25f);
	CGContextAddLineToPoint(context, sizeInPixels.width*0.375, sizeInPixels.height/2.0f);
	CGContextAddLineToPoint(context, sizeInPixels.width*0.625f, sizeInPixels.height*0.75f);
	CGContextStrokePath(context);

	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:0];
	CGImageRelease(imgRef);

	return img;
}

+ (UIImage*)backgroudImageWithColor:(UIColor*)bgColor
{
	static NSMutableDictionary* dic = nil;
	if(dic==nil)
		dic = [NSMutableDictionary new];
	UIImage* img = dic[[bgColor description]];
	if(img==nil)
	{
		img = [self createBacggroundImageWithColor:bgColor];
		dic[[bgColor description]] = img;
	}
	return img;
}
+ (UIImage*)createBacggroundImageWithColor:(UIColor*)bgColor
{
	CGSize size = CGSizeMake(4, 4);
	CGSize sizeInPixels;
	CGFloat scale = [UIScreen mainScreen].scale;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;

	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

	CGColorSpaceRelease(colorSpace);

//	CGFloat rgba[4];
//	[bgColor getRed:rgba+3 green:rgba+1 blue:rgba+2 alpha:rgba];
	CGFloat rgba[4] = {0,0,0,1.0};
	CGContextSetFillColor(context, rgba);
	CGContextFillRect(context, CGRectMake(0, 0, sizeInPixels.width, sizeInPixels.height));

	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:0];
	CGImageRelease(imgRef);

	return img;//[img resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
}

+ (UIImage*)imageWithSize:(CGSize)size color:(UIColor*)bgColor
{
	if(size.width<=0 || size.height<=0)
		return nil;
	CGSize sizeInPixels;
	CGFloat scale = [UIScreen mainScreen].scale;
	sizeInPixels.width = size.width*scale;
	sizeInPixels.height = size.height*scale;

	int bytesPerRow	= 4*sizeInPixels.width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL,
												 sizeInPixels.width,
												 sizeInPixels.height,
												 8,
												 bytesPerRow,
												 colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);

	CGFloat rgba[4];
	[bgColor getRed:rgba green:rgba+1 blue:rgba+2 alpha:rgba+3];
	CGContextSetRGBFillColor(context, rgba[0], rgba[1], rgba[2], rgba[3]);
	CGContextFillRect(context, CGRectMake(0, 0, sizeInPixels.width, sizeInPixels.height));

	CGImageRef imgRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:0];
	CGImageRelease(imgRef);

	return img;
}

@end
