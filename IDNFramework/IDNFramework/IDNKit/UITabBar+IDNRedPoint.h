//
//  UITabBar+IDNRedPoint.h
//
//  Created by photondragon on 15/7/24.
//

#import <UIKit/UIKit.h>

@interface UITabBar(IDNRedPoint)

- (void)showRedPointAtItemIndex:(int)index; //显示小红点
- (void)hideRedPointAtItemIndex:(int)index; //隐藏小红点
- (BOOL)isShowingRedPointAtItemIndex:(int)index;

@end
