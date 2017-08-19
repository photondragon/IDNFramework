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

- (NSString*)urlParamsString;

#pragma mark - dic <==> json
+ (NSDictionary*)dictionaryWithJSONData:(NSData*)jsonData error:(NSError**)error;

- (NSString*)jsonString;
- (NSData*)jsonData;

@end
