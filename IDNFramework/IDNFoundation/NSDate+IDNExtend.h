//
//  NSDate+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/4/12.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(IDNExtend)

+ (NSString*)dateFormatGMT; //@"EEE, dd MMM yyyy HH:mm:ss Z"
- (NSString*)stringWithFormat:(NSString*)format; //format示例：@"yyyyMMddHHmmssFFF"
+ (NSDate*)dateFromString:(NSString*)dateString format:(NSString*)format; //0时区

@end
