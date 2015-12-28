//
//  NSDictionary+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary(IDNExtend)

- (NSDictionary*)dictionaryWithoutNSNull;
- (NSString *)jsonString;

@end
