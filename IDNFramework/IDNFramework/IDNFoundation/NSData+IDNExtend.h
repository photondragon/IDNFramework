//
//  NSData+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData(IDNExtend)

#pragma mark file & dir

- (BOOL)writeToDocumentFile:(NSString *)file; //将数据保存到Documents目录下，文件名为file（相对路径，可以包含子目录，如果子目录不存在，会自动创建）

#pragma mark hash

- (NSString *)md2;
- (NSString *)md4;
///输出16进制显示的md5（32个字节）
- (NSString *)md5;

- (NSString *)sha1;
- (NSString *)sha224;
- (NSString *)sha256;
- (NSString *)sha384;
- (NSString *)sha512;

#pragma mark Crypto

- (NSData*)encrypt3DESWithKey:(NSString *)key;
- (NSString *)decrypt3DESWithkey:(NSString *)key;

@end
