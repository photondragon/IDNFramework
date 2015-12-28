//
//  NSString+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(IDNExtend)

#pragma mark - file & dir
+ (NSString*)documentsPath;

+ (NSString*)documentsPathWithFileName:(NSString*)fileName;
- (BOOL)mkdir; //创建目录（会创建中间目录）
- (NSDictionary*)parseURLParameters; //把self当作URL地址中的参数部分来解析，返回的字典中的key和value均为字符串。解析形如res=user&uid=123456的字符串。

#pragma mark - hash

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

#pragma mark - encoding

// -[NSString stringByAddingPercentEscapesUsingEncoding:]不会转换斜杠/等字符，而本函数转换所有字符
- (NSString *)urlEncoding;

#pragma mark - Crypto

- (NSData*)encrypt3DESWithKey:(NSString *)key;

#pragma mark - 字符串检测处理

- (NSString*)trim; //删除头尾的空白字符
- (NSString*)truncateWithLength:(NSUInteger)length; //截断到指定长度. 如果字符串小于指定长度, 则返回原始NSString对象
- (BOOL)isNotPureNumeric; //是否不是纯数字. 如果是空串, 返回NO
- (BOOL)isNotPureAlphabet; //是否不是纯字母. 如果是空串, 返回NO
- (NSString*)stringByRemovingCharactersInSet:(NSCharacterSet*)charSet; //删除指定字符. 如果没有删除任何字符, 则返回原始NSString对象

- (NSDictionary*)dictionaryFromJson;

@end
