//
//  NSString+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/3/29.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSString+IDNExtend.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString(IDNExtend)

+ (NSString*)documentsPath
{
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths firstObject];
}

+ (NSString*)documentsPathWithFileName:(NSString*)fileName
{
	if(fileName.length==0)
		return nil;
	return [NSString stringWithFormat:@"%@/%@", [self documentsPath], fileName];
}

#pragma mark hash

//- (NSString *)md5
//{
//	const char *cStr = [self UTF8String];
//	unsigned char result[CC_MD5_DIGEST_LENGTH];
//	CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
//	return [NSString stringWithFormat:
//			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//			result[0], result[1], result[2], result[3],
//			result[4], result[5], result[6], result[7],
//			result[8], result[9], result[10], result[11],
//			result[12], result[13], result[14], result[15]
//			];
//}
- (NSString*)md2
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char buffer[CC_MD2_DIGEST_LENGTH];
	CC_MD2(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD2_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD2_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString*)md4
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char buffer[CC_MD4_DIGEST_LENGTH];
	CC_MD4(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD4_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD4_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString*)md5
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", buffer[i]];
	return output;
}

- (NSString *)sha1
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t buffer[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha224
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t buffer[CC_SHA224_DIGEST_LENGTH];
	CC_SHA224(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA224_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA224_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha256
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t buffer[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha384
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t buffer[CC_SHA384_DIGEST_LENGTH];
	CC_SHA384(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA384_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA384_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSString *)sha512
{
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t buffer[CC_SHA512_DIGEST_LENGTH];
	CC_SHA512(data.bytes, (CC_LONG)data.length, buffer);
	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

- (NSData*)hmacSha1DataWithKey:(NSString *)key
{
	const char *cKey  = key.UTF8String;
	const char *cData = self.UTF8String;
	char buffer[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), buffer);
	return [[NSData alloc] initWithBytes:buffer length:CC_SHA1_DIGEST_LENGTH];
}
- (NSString*)hmacSha1WithKey:(NSString *)key
{
	const char *cKey  = key.UTF8String;
	const char *cData = self.UTF8String;
	char buffer[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), buffer);

	NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x", buffer[i]];
	}
	return output;
}

#pragma mark encoding

// -[NSString stringByAddingPercentEscapesUsingEncoding:]不会转换斜杠/等字符，而本函数转换所有字符
- (NSString *)urlEncoding
{
	NSMutableString *output = [NSMutableString string];
	const unsigned char *source = (const unsigned char *)[self UTF8String];
	int sourceLen = (int)strlen((const char *)source);
	for (int i = 0; i < sourceLen; ++i) {
		const unsigned char thisChar = source[i];
		if (thisChar == ' '){
			[output appendString:@"+"];
		} else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
				   (thisChar >= 'a' && thisChar <= 'z') ||
				   (thisChar >= 'A' && thisChar <= 'Z') ||
				   (thisChar >= '0' && thisChar <= '9')) {
			[output appendFormat:@"%c", thisChar];
		} else {
			[output appendFormat:@"%%%02X", thisChar];
		}
	}
	return output;
}

#pragma mark Crypto

- (NSData*)encrypt3DESWithKey:(NSString *)key
{
	const char* dataString = [self UTF8String];
	size_t dataLength = strlen(dataString)+1;

	size_t bufferLength = (dataLength+kCCBlockSize3DES-1)/kCCBlockSize3DES*kCCBlockSize3DES;
	unsigned char* buffer = malloc(bufferLength);
	memset(buffer, 0, bufferLength);

	size_t outDataLength = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithm3DES,
										  kCCOptionPKCS7Padding,
										  [key UTF8String], kCCKeySize3DES,
										  nil,
										  dataString, dataLength,
										  buffer, bufferLength,
										  &outDataLength);
	NSData* retData;
	if (cryptStatus == kCCSuccess)
		retData = [NSData dataWithBytes:buffer length:(NSUInteger)outDataLength];
	else
		retData = nil;
	free(buffer);
	return retData;
}

@end
