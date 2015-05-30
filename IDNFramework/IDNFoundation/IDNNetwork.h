//
//  IDNNetwork.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

//字典参数会被转为JSON格式（UTF8编码）发送

@interface IDNNetwork : NSObject

#pragma mark 服务器时间同步

// 自动从每个GET请求中获取服务器时间，与本地时间进行比对，误差在1分钟以内不做校正。
+ (NSDate*)dateOfServer; //返回服务器时间
+ (NSTimeInterval)timeIntervalOfServerSinceReferenceDate; //返回服务器时间

#pragma mark GET
+ (NSDictionary*)getDictionaryFromURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error; //GET url?p=parameters
+ (NSData*)getFromURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error;

#pragma mark POST
// 以POST方式访问指定URL，参数以UTF8编码的JSON格式发送
+ (NSDictionary*)postToURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error;
+ (NSData*)postToURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error;

#pragma mark PUT
+ (NSDictionary*)putToURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error;
+ (NSData*)putToURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error;

#pragma mark DELETE
+ (NSDictionary*)deleteAtURL:(NSString*)url parameters:(NSDictionary*)parameters error:(NSError**)error;
+ (NSData*)deleteAtURL:(NSString*)url bodyData:(NSData*)bodyData error:(NSError**)error;

#pragma mark JSON<=>字典
// 便利方法
+ (NSDictionary*)dictionaryFromJSONData:(NSData*)jsonData error:(NSError**)error;
+ (NSData*)jsonDataFromDictionary:(NSDictionary*)dic error:(NSError**)error;
+ (NSString*)jsonStringFromDictionary:(NSDictionary*)dic error:(NSError**)error;

@end

