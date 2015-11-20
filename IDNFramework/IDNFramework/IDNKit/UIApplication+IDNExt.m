//
//  UIApplication+IDNExt.m
//  IDNFramework
//
//  Created by photondragon on 15/11/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UIApplication+IDNExt.h"

@implementation UIApplication(IDNExt)

+ (id<UIApplicationDelegate>)appDelegate
{
	return [UIApplication sharedApplication].delegate;
}

@end
