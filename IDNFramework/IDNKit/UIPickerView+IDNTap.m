//
//  UIPickerView+IDNTap.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIPickerView+IDNTap.h"
#import <objc/runtime.h>

@implementation UIPickerView(IDNTap)

static char pickerViewTapKey = 0;

- (void (^)(UIPickerView*, NSUInteger))currentRowTappedBlock
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &pickerViewTapKey);
	return dic[@"block"];
}

- (void)setCurrentRowTappedBlock:(void (^)(UIPickerView*, NSUInteger))tappedBlock
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &pickerViewTapKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &pickerViewTapKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	if(tappedBlock)
	{
		dic[@"block"] = tappedBlock;
		UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnUIPickerViewTap:)];
		tap.delegate = self;
		[self addGestureRecognizer:tap];
		dic[@"tapGesture"] = tap;
	}
	else if(dic[@"block"])
	{
		[self removeGestureRecognizer:dic[@"tapGesture"]];
		dic[@"block"] = nil;
		dic[@"tapGesture"] = nil;
	}
}

- (void)tapOnUIPickerViewTap:(UITapGestureRecognizer*)tapGesture
{
	CGSize framesize = self.frame.size;
	CGSize rowsize = [self rowSizeForComponent:0];
	if(rowsize.height<=0)
		return;
	
	CGFloat y = (framesize.height - rowsize.height)/2.0;
	CGPoint point = [tapGesture locationInView:self];
	if(point.y<y || point.y>=y+rowsize.height)
		return;
	
	NSInteger componentsCount = self.numberOfComponents;
	CGFloat x = 0;
	CGFloat width = 0;
	for (NSInteger i = 0; i<componentsCount; i++) {
		CGSize rowsize = [self rowSizeForComponent:i];
//		NSLog(@"%@", [NSValue valueWithCGSize:rowsize]);
		width += rowsize.width;
	}
	
	CGFloat interval;
	if(componentsCount>1)
		interval = (framesize.width - width)/(componentsCount-1);
	else
		interval = 0;
	
	for (NSInteger i = 0; i<componentsCount; i++) {
		CGSize rowsize = [self rowSizeForComponent:i];
		x +=rowsize.width + interval/2.0;
		if(point.x<x)
		{
			self.currentRowTappedBlock(self, i);
			return;
		}
		x += interval/2.0;
	}
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

@end
