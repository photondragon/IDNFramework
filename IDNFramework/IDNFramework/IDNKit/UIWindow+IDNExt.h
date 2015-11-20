//
//  UIWindow+IDNExt.h
//  IDNFramework
//
//  Created by photondragon on 15/11/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow(IDNExt)

+ (UIWindow*)mainWindow;
+ (UIViewController*)rootViewController;
+ (UIViewController*)presentedViewController;

@end
