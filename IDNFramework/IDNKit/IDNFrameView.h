//
//  IDNFrameView.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, DrawEdgeLine) {
	DrawEdgeLineNone = 0,
	DrawEdgeLineAll = -1,
	DrawEdgeLineLeft = 1<<0,
	DrawEdgeLineRight = 1<<1,
	DrawEdgeLineTop = 1<<2,
	DrawEdgeLineBottom = 1<<3,
};

// 四边各画一条1pixel宽的线的view
@interface IDNFrameView : UIView

@property(nonatomic) DrawEdgeLine drawEdgeLines; //画哪几条边线。默认DrawEdgeLineNone
@property(nonatomic,strong) UIColor* frameColor; //边框颜色。默认[UIColor colorWithWhite:0.85 alpha:1.0];
@property(nonatomic) CGFloat frameLineWidth; //边框线宽。默认1像素

@end
