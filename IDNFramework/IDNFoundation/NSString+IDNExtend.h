//
//  NSString+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(IDNExtend)

+ (NSString*)documentsPath;

+ (NSString*)documentsPathWithFileName:(NSString*)fileName;

#pragma mark hash

- (NSString *)md5;

@end
