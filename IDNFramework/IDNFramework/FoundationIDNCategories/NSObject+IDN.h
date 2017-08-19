//
//  NSObject+IDN.h
//  xiangyue3
//
//  Created by photondragon on 16/3/23.
//  Copyright © 2016年 Shendou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(IDN)

- (BOOL)isKindOfNSNull;
- (BOOL)isKindOfNSError;
- (BOOL)isKindOfNSString;
- (BOOL)isKindOfNSNumber;
- (BOOL)isKindOfNSArray;
- (BOOL)isKindOfNSDictionary;
- (BOOL)isMemberOfNSError;
- (BOOL)isMemberOfNSString;
- (BOOL)isMemberOfNSNumber;
- (BOOL)isMemberOfNSArray;
- (BOOL)isMemberOfNSDictionary;

@end
