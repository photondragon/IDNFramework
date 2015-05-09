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
- (UIImage *)imageWithoutOrientation;

@end
