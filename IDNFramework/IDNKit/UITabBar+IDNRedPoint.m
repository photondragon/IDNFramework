//
//  UITabBar+IDNRedPoint.m
//
//  Created by photondragon on 15/7/24.
//

#import "UITabBar+IDNRedPoint.h"

#define TagStartIndex 79284

@implementation UITabBar(IDNRedPoint)

- (void)showRedPointAtItemIndex:(int)index
{
	if(index<0 || index>=self.items.count)
		return;
	
	//移除之前的小红点
	[self hideRedPointAtItemIndex:index];
	
	//新建小红点
	UIView *badgeView = [[UIView alloc]init];
	badgeView.tag = TagStartIndex + index;
	badgeView.layer.cornerRadius = 5;
	badgeView.backgroundColor = [UIColor redColor];
	CGRect tabFrame = self.frame;
	
	//确定小红点的位置
	float percentX = (index +0.6) / self.items.count;
	CGFloat x = ceilf(percentX * tabFrame.size.width);
	CGFloat y = ceilf(0.1 * tabFrame.size.height);
	badgeView.frame = CGRectMake(x, y, 10, 10);
	[self addSubview:badgeView];
	
}

- (void)hideRedPointAtItemIndex:(int)index
{
	if(index<0)
		return;
	//按照tag值移除小红点
	UIView* redpointView = [self viewWithTag:TagStartIndex+index];
	[redpointView removeFromSuperview];
}

- (BOOL)isShowingRedPointAtItemIndex:(int)index
{
	if(index<0 || index>=self.items.count)
		return NO;
	UIView* redpointView = [self viewWithTag:TagStartIndex+index];
	if(redpointView)
		return YES;
	return NO;
}

@end
