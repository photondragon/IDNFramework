//
//  IDNTapGestureShadowRecognizer.h
//  IDNFramework
//
//  Created by photondragon on 15/7/23.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 这个手势永远不会进入Ended/Recognied状态，但是如果检测到Tap手势，会调用[tapTarget tapSelector];
// 因为UITableView检测Tap手势时会检测是否有其它手势recognized，如果有，则UITableView的Tap手势不会生效，这会导致cell无法被选中。所以需要一个永远不会Recognized的Tap手势
@interface IDNTapGestureShadowRecognizer : UITapGestureRecognizer

- (void)setTapTarget:(id)tapTarget tapSelector:(SEL)tapSelector;

@end
