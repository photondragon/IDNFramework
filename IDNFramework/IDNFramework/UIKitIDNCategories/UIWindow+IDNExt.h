//
//  UIWindow+IDNExt.h
//  IDNFramework
//
//  Created by photondragon on 15/11/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

#define WindowCustomViewTag 4866522

@interface UIWindow(IDNExt)

+ (UIWindow*)mainWindow;
+ (UIViewController*)rootViewController;
+ (UIViewController*)presentedViewController;

- (void)removeAllCustomViews;

@end
