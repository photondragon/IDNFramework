//
//  NSData+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSData+IDNExtend.h"
#import "NSString+IDNExtend.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>


@implementation NSData(IDNExtend)

#pragma mark file & dir

- (BOOL)writeToDocumentFile:(NSString *)file
{
	NSString* documentsDir = [NSString documentsPath];
	if ([file rangeOfString:@"/"].location != NSNotFound)//包含子目录
	{
		NSString* dir = [file stringByDeletingLastPathComponent];
		NSString* dirFullPath = [NSString stringWithFormat:@"%@/%@", documentsDir, dir];
		if([[NSFileManager defaultManager] fileExistsAtPath:dirFullPath]==NO)//目录不存在
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:dirFullPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}
	NSString* fullPath = [NSString stringWithFormat:@"%@/%@", documentsDir, file];
	return [self writeToFile:fullPath atomically:YES];
}

#pragma mark hash

- (NSString*)md2
{
	unsigned char buffer[CC_MD2_DIGEST_LENGTH];
	CC_MD2(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD2_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD2_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString*)md4
{
	unsigned char buffer[CC_MD4_DIGEST_LENGTH];
	CC_MD4(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD4_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD4_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString*)md5
{
	unsigned char buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString *)sha1
{
	uint8_t buffer[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha224
{
	uint8_t buffer[CC_SHA224_DIGEST_LENGTH];
	CC_SHA224(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA224_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA224_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha256
{
	uint8_t buffer[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha384
{
	uint8_t buffer[CC_SHA384_DIGEST_LENGTH];
	CC_SHA384(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA384_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA384_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha512
{
	uint8_t buffer[CC_SHA512_DIGEST_LENGTH];
	CC_SHA512(self.bytes, (CC_LONG)self.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

#pragma mark Crypto

- (NSData*)encrypt3DESWithKey:(NSString *)key
{
	const char* dataBytes = [self bytes];
	size_t dataLength = self.length;

	size_t bufferLength = (dataLength+kCCBlockSize3DES)/kCCBlockSize3DES*kCCBlockSize3DES;
	unsigned char* buffer = malloc(bufferLength);
	memset(buffer, 0, bufferLength);

	size_t outDataLength = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithm3DES,
										  kCCOptionPKCS7Padding,
										  [key UTF8String], kCCKeySize3DES,
										  nil,
										  dataBytes, dataLength,
										  buffer, bufferLength,
										  &outDataLength);
	NSData* data;
	if (cryptStatus == kCCSuccess)
		data = [NSData dataWithBytes:buffer length:(NSUInteger)outDataLength];
	else
		data = nil;
	free(buffer);
	return data;
}

- (NSString *)decrypt3DESWithkey:(NSString *)key
{
	const void* data = [self bytes];
	size_t dataLength = self.length;

	if(dataLength%kCCBlockSize3DES!=0)
		return nil;

	size_t bufferLength = dataLength;
	char* buffer = malloc(bufferLength);
	memset(buffer, 0, bufferLength);

	size_t outDataLength = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,//解密
										  kCCAlgorithm3DES,//算法
										  kCCOptionPKCS7Padding,//选项
										  [key UTF8String], kCCKeySize3DES,//key及其length
										  nil,//Initialization vector, optional
										  data,//dataIn
										  dataLength,//dataInLength
										  buffer,//dataOutBuffer
										  bufferLength,//dataOutBufferLength
										  &outDataLength);//dataOutLength
	NSString* retstr;
	if (cryptStatus == kCCSuccess)
	{
		NSData* data = [NSData dataWithBytes:buffer length:(NSUInteger)outDataLength];
		retstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	else
		retstr = nil;
	free(buffer);
	return retstr;
}

@end
