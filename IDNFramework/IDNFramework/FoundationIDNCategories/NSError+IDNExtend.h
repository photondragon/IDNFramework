//
//  NSError+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError(IDNExtend)

+ (instancetype)errorDescription:(NSString*)description;
+ (instancetype)errorWithDomain:(NSString *)domain description:(NSString*)description;

@end
