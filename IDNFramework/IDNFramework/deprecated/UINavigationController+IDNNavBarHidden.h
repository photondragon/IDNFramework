//
//  UINavigationController+IDNNavBarHidden.h
//
//  Created by photondragon on 15/9/28.

#import <UIKit/UIKit.h>

@interface UINavigationController(IDNNavBarHidden)

@property (nonatomic, assign) BOOL idn_controllerBasedNavBarHiddenEnabled;

@end

@interface UIViewController (IDNNavBarHidden)

@property (nonatomic, assign) BOOL idn_prefersNavigationBarHidden;

@end