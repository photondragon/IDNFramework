//
//  NSURLRequest+IDN.h
//  IDNFramework
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest(IDN)

+ (instancetype)requestWithURLString:(NSString *)URLString;

@end
