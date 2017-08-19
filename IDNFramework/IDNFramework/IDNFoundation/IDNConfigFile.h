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

 假设你的程序有配置文件，是从服务器上下载得到的，可以通过修改服务器上的配置文件
 来改变应用程序的行为。
 IDNConfigFile类就是帮你管理这个配置文件的（下载、自动更新）

 完全通过类方法来使用，不需要创建任何配置类的对象。
 可以使用多套配置，在运行时进行切换，从而改变应用行为（这个特性主要是为了方便开发和测试）。

 简单应用：
 一个配置文件。
 
 中级应用：
 多个配置文件。

 高级应用：
 多个配置文件，多个环境（开发、测试、正式）。

 假设你开发了一个应用，这个应用有多个业务，每个业务都有一个配置文件，是从服务器上下载下来的。
 为了方便开发和测试，现在你有三台不同的服务器，分别是开发（本机）、测试、正式服务器。
 我们通过在登录界面加了个开关，可以在三台服务器之间进行切换。

 使用时应该定义此类的子类，但不需要创建任何子类的对象，只通过类方法来使用。
 
 env用来区分不同的服务器（开发、测试、正式）
 不同的子类用来区分不同的业务的配置文件，比如有一个主要配置文件，还有一个广告的配置文件。
 */
@interface IDNConfigFile : NSObject

#pragma mark - 设置

/**
 *  设置配置文件信息。建议在程序启动后调用。特定子类的这个方法只能调用一次，调用多次是无效的。
 *
 *  @param cfgUrl               配置文件的下载地址，必须是Json格式。如果为nil，可以通过调用manualRefreshWith*系列方法来手动设置配置信息
 *  @param refreshInterval      配置文件的自动刷新时间间隔
 *  @param forceRefreshOnLaunch 程序启动时是否强制刷新配置文件（准确地说是调用这个方法之后立即异步刷新。因为一般情况下是在程序启动时调用这个方法，所以这个参数就取名为“启动时强制刷新”）
 *  @param defaultJsonFile      默认的配置文件，内容必须是Json，这个文件必须保存在mainBundle中。当程序首次启动时，没有任何配置信息，因为配置信息一般是从网络上下载来的。这个参数可以让你指定一个“默认”的配置信息，这样可以保证程序在首次启动时，即使没有网络，下载不到最新的配置文件，也有默认的配置信息。
 *  @param env                  配置文件对应的环境名，如果设置为nil,NSNull，则相当于@""
 */
+ (void)setupWithUrl:(NSString*)cfgUrl refreshInterval:(NSTimeInterval)refreshInterval forceRefreshOnLaunch:(BOOL)forceRefreshOnLaunch defaultJsonFile:(NSString*)defaultJsonFile forEnv:(NSString*)env;

#pragma mark - 全局环境（由IDNConfigFile类及其所有子类共享）

+ (NSString*)currentEnv; //获取当前的全局环境。默认返回第一个配置的环境名，如果一套配置也没有，返回nil
+ (void)switchToEnv:(NSString*)env; //切换到指定环境。nil,NSNull相当于@""
+ (NSArray*)allEnvs; //获取所有全局环境的名称列表

#pragma mark - 配置信息（当前子类、当前环境下的）

+ (NSDictionary*)configuration; //返回当前环境下的配置信息，如果当前环境没有相关的配置信息，则返回默认环境下的配置信息，如果

+ (void)configurationRefreshed; //重载点。（手动/自动）刷新配置信息后，此方法会被调用，子类可以重载此方法，作一些后续处理工作。默认实现是空函数，所以无需调用[super configFileUpdated]

#pragma mark - 手动设置（当前环境下的）配置信息
+ (void)manualRefreshWithJsonFile:(NSString*)jsonFilePath; //jsonFilePath为本地json文件全路径名文件名
+ (void)manualRefreshWithJsonString:(NSString*)jsonString; //jsonString为json字符串
+ (void)manualRefreshWithData:(NSData*)data; //data内容必须是json格式
+ (void)manualRefreshWithDictionary:(NSDictionary*)dicConfig; //designated method

@end
