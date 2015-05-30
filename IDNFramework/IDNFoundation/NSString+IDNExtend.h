//
//  NSString+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(IDNExtend)

#pragma mark file & dir
+ (NSString*)documentsPath;

+ (NSString*)documentsPathWithFileName:(NSString*)fileName;

#pragma mark hash

- (NSString *)md2;
- (NSString *)md4;
- (NSString *)md5; //输出16进制显示的md5（32个字节）

- (NSString *)sha1;
- (NSString *)sha224;
- (NSString *)sha256;
- (NSString *)sha384;
- (NSString *)sha512;

- (NSData*)hmacSha1DataWithKey:(NSString *)key;
- (NSString*)hmacSha1WithKey:(NSString *)key;

#pragma mark encoding

// -[NSString stringByAddingPercentEscapesUsingEncoding:]不会转换斜杠/等字符，而本函数转换所有字符
- (NSString *)urlEncoding;

#pragma mark Crypto

- (NSData*)encrypt3DESWithKey:(NSString *)key;

@end
