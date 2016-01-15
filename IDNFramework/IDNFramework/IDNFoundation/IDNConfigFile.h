//
//  IDNConfigFile.h
//  IDNFramework
//
//  Created by photondragon on 15/8/19.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 配置文件类

 假设你的程序有一个配置文件，是从服务器上下载得到的，你可以通过修改服务器上的这个配置文件
 来改变应用程序的行为。
 IDNConfigFile类就是帮你管理这个配置文件的（下载、自动更新）
 */
@interface IDNConfigFile : NSObject

+ (NSDictionary*)configDict; //包含配置信息的字典

/**
 *  注册配置文件类。在使用配置文件类之前，必须先注册。建议在程序一启动后就注册。
 *
 *  @param cfgUrl               配置文件的下载地址，必须是Json格式。如果为nil，可以通过调用manualRefreshWith*系列方法来手动设置配置信息
 *  @param refreshInterval      配置文件的自动刷新时间间隔
 *  @param forceRefreshOnLaunch 程序启动时是否强制刷新配置文件
 *  @param defaultJsonFile      默认的配置文件名，内容必须是Json，这个文件必须保存在mainBundle中。当程序首次启动时，没有任何配置信息，因为配置信息一般是从网络上下载来的。这个参数可以让你指定一个“默认”的配置信息，这样可以保证程序在首次启动时，即使没有网络，下载不到最新的配置文件，也有默认的配置信息。
 */
+ (void)registerWithUrl:(NSString*)cfgUrl refreshInterval:(NSTimeInterval)refreshInterval forceRefreshOnLaunch:(BOOL)forceRefreshOnLaunch defaultJsonFile:(NSString*)defaultJsonFile;

#pragma mark - 手动刷新配置文件
+ (void)manualRefreshWithJsonFile:(NSString*)jsonFilePath; //jsonFilePath为本地json文件全路径名文件名
+ (void)manualRefreshWithJsonString:(NSString*)jsonString; //jsonString为json字符串
+ (void)manualRefreshWithData:(NSData*)data; //data内容必须是json格式
+ (void)manualRefreshWithDictionary:(NSDictionary*)dicConfig; //designated method

+ (void)configRefreshed; //重载点。（手动/自动）刷新配置信息后，此方法会被调用，子类可以重载此方法，作一些后续处理工作。默认实现是空函数，所以无需调用[super configFileUpdated]

@end
