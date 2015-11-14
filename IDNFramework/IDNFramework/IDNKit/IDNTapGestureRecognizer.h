//
//  IDNTapGestureRecognizer.h
//  IDNFramework
//
//  Created by photondragon on 15/7/23.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 这个手势永远不会进入Ended/Recognied状态，但是如果检测到Tap手势，会调用[tapTarget tapSelector];
// 因为TableViewCell的点击检测手势会检测其它手势是否成功，如果成功，则TableViewCell的选中永远不会发生。所以需要一个永远不会Recognized的Tap手势
@interface IDNTapGestureRecognizer : UITapGestureRecognizer

- (void)setTapTarget:(id)tapTarget tapSelector:(SEL)tapSelector;

@end
