//
//  UIImage+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/5/9.
//  Copyright (c) 2015年 no. All rights reserved.
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

- (UIImage *)resizedImageWithAspectFitSize:(CGSize)size
{
	if(size.width<=0 || size.height<=0)
		return nil;
	CGSize originSize = self.size;
	CGFloat wRatio = size.width/originSize.width;
	CGFloat hRatio = size.height/originSize.height;
	CGFloat ratio = wRatio<hRatio ? wRatio : hRatio;
	CGSize newSize = CGSizeMake((int)(originSize.width*ratio), (int)(originSize.height*ratio));
	return [self resizedImageWithSize:newSize];
}

- (UIImage *)resizedImageWithAspectFillSize:(CGSize)size
{
	if(size.width<=0 || size.height<=0)
		return nil;
	CGSize originSize = self.size;
	CGFloat wRatio = size.width/originSize.width;
	CGFloat hRatio = size.height/originSize.height;
	CGFloat ratio = wRatio>hRatio ? wRatio : hRatio;
	CGSize newSize = CGSizeMake((int)(originSize.width*ratio), (int)(originSize.height*ratio));
	return [self resizedImageWithSize:newSize];
}

@end
