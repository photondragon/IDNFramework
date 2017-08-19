//
//  NSURL+IDN.h
//  xiangyue3
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL(IDN)

+ (instancetype)URLWithString:(NSString *)URLString params:(NSDictionary*)params; //params作为Get的参数，拼在URLString的后面。

@end
