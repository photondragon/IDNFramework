//
//  UIView+IDNZoom.m
//  IDNFramework
//
//  Created by photondragon on 15/6/29.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIView+IDNZoom.h"
#import <objc/runtime.h>

@implementation UIView(IDNZoom)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfUIViewIDNZoomBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (CGFloat)zoomRatio
{
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNZoomBindData];
	NSNumber *number = dic[@"zoomRatio"];
	if(number){
		return [number floatValue];
	}else{
		return 1;
	}
}

- (void)setZoomRatio:(CGFloat)ratio
{
	[self setZoomRatio:ratio recursive:NO ignoreViews:nil];
}
- (void)setZoomRatio:(CGFloat)ratio recursive:(BOOL)recursive
{
	[self setZoomRatio:ratio recursive:recursive ignoreViews:nil];
}
- (void)setZoomRatio:(CGFloat)ratio recursive:(BOOL)recursive ignoreViews:(NSArray*)ignoreViews //recursive表示是否递归，ignorelist表示忽略
{
	if(ratio<=0)
		return;
	
	if(ignoreViews && [ignoreViews indexOfObjectIdenticalTo:self]!=NSNotFound)
		return;
	
	NSMutableDictionary* dic = [self dictionaryOfUIViewIDNZoomBindData];
	NSNumber *ratioNumber = dic[@"zoomRatio"];

	CGFloat currentRatio;
	if(ratioNumber)
		currentRatio = ratioNumber.floatValue;
	else
		currentRatio = 1.0;
	if(currentRatio==ratio)
		return;
	CGFloat deltaRatio = ratio/currentRatio;
	
	CGPoint center;
	CGRect bounds;
	NSValue* centerValue = dic[@"center"];
	NSValue* boundsValue = dic[@"bounds"];
	if(centerValue)
		center = [centerValue CGPointValue];
	else
	{
		center = self.center;
		dic[@"center"] = [NSValue valueWithCGPoint:center];
	}
	if(boundsValue)
		bounds = [boundsValue CGRectValue];
	else
	{
		bounds = self.bounds;
		dic[@"bounds"] = [NSValue valueWithCGRect:bounds];
	}
	
	CGPoint newCenter;
	CGRect newBounds;
	newCenter.x = center.x*ratio;
	newCenter.y = center.y*ratio;
	newBounds.origin = CGPointZero;
	newBounds.size.width = bounds.size.width*ratio;
	newBounds.size.height = bounds.size.height*ratio;
	
	if([self isKindOfClass:[UIScrollView class]]){
		if([self isKindOfClass:[UITableView class]]==NO)
		{
			UIScrollView *sv = (UIScrollView*)self;
			CGSize originContentSize;
			CGPoint originContentOffset;
			if(dic[@"originContentSize"])
			{
				originContentSize = [dic[@"originContentSize"] CGSizeValue];
				originContentOffset = [dic[@"originContentOffset"] CGPointValue];
			}
			else
			{
				originContentSize = sv.contentSize;
				dic[@"originContentSize"] = [NSValue valueWithCGSize:originContentSize];
				originContentOffset = sv.contentOffset;
				dic[@"originContentOffset"] = [NSValue valueWithCGPoint:originContentOffset];
			}
			sv.contentSize = CGSizeMake(roundf(originContentSize.width*ratio), roundf(originContentSize.height*ratio));
			sv.contentOffset = CGPointMake(originContentOffset.x*ratio, originContentOffset.y*ratio);
		}
	}
	else if([self isKindOfClass:[UILabel class]] ||
			[self isKindOfClass:[UITextField class]] ||
			[self isKindOfClass:[UITextView class]]){
		UILabel *label = (UILabel*)self;
		UIFont* originFont;
		if(dic[@"originFont"])
			originFont = dic[@"originFont"];
		else
		{
			originFont = label.font;
			dic[@"originFont"] = originFont;
		}
		label.font = [UIFont fontWithName:originFont.fontName size:originFont.pointSize*ratio];
	}
	else if([self isKindOfClass:[UIButton class]]){
		UIButton *btn = (UIButton*)self;
		UIFont* originFont;
		if(dic[@"originFont"])
			originFont = dic[@"originFont"];
		else
		{
			originFont = btn.titleLabel.font;
			dic[@"originFont"] = originFont;
		}
		btn.titleLabel.font = [UIFont fontWithName:originFont.fontName size:originFont.pointSize*deltaRatio];
	}
	else if([self isKindOfClass:[UISwitch class]])
	{
		newBounds = bounds; //UISwitch不放大，只调整center
	}
	
	CGRect rect;
	rect.origin.x = roundf(newCenter.x-newBounds.size.width/2.0);
	rect.origin.y = roundf(newCenter.y-newBounds.size.height/2.0);
	rect.size.width = roundf(newCenter.x+newBounds.size.width/2.0) - rect.origin.x;
	rect.size.height = roundf(newCenter.y+newBounds.size.height/2.0) - rect.origin.y;
	self.frame = rect;
//	self.bounds = newBounds;
//	self.center = newCenter;
	
	CGFloat borderWidth;
	CGFloat cornerRadius;
	if(dic[@"borderWidth"])
		borderWidth = [dic[@"borderWidth"] floatValue];
	else
	{
		borderWidth = self.layer.borderWidth;
		dic[@"borderWidth"] = @(borderWidth);
	}
	if(dic[@"cornerRadius"])
		cornerRadius = [dic[@"cornerRadius"] floatValue];
	else
	{
		cornerRadius = self.layer.cornerRadius;
		dic[@"cornerRadius"] = @(cornerRadius);
	}
	self.layer.borderWidth = borderWidth*ratio;
	self.layer.cornerRadius = cornerRadius*ratio;
	
	if(ratio==1.0)
	{
		objc_setAssociatedObject(self, &bindDataKey, nil, OBJC_ASSOCIATION_RETAIN);
	}
	
	if(recursive &&
	   [self isKindOfClass:[UITableView class]]==NO && //忽略TableView的所有子View
	   [self isKindOfClass:[UISwitch class]]==NO) //忽略UISwitch的所有子View
	{
		for (UIView* subview in self.subviews) {
			[subview setZoomRatio:ratio recursive:recursive ignoreViews:ignoreViews];
		}
	}
}

- (void)zoomSubviewsWithRatio:(CGFloat)ratio
{
	[self zoomSubviewsWithRatio:ratio recursive:NO ignoreViews:nil];
}
- (void)zoomSubviewsWithRatio:(CGFloat)ratio recursive:(BOOL)recursive
{
	[self zoomSubviewsWithRatio:ratio recursive:recursive ignoreViews:nil];
}
- (void)zoomSubviewsWithRatio:(CGFloat)ratio recursive:(BOOL)recursive ignoreViews:(NSArray*)ignoreViews;
{
	for(UIView *view in self.subviews){
		[view setZoomRatio:ratio recursive:recursive ignoreViews:ignoreViews];
	}
}

@end
