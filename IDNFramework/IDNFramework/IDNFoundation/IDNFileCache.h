//
//  IDNFileCache.h
//  IDNFramework
//
//  Created by photondragon on 15/6/22.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IDNFileCacheAgeADay 3600.0*24.0
#define IDNFileCacheAgeAWeek 3600.0*24.0*7
#define IDNFileCacheAgeAMonth 3600.0*24.0*30

/** 文件缓存器。
 除了-initWithLoalCacheDir:方法，其它方法都是线程安全的
 将数据缓存到本地磁盘上的文件中。一般用来缓存网络Get请求的数据或者小图片之类。
 不考虑超大文件的问题，超大文件的缓存应考虑其它解决方案。
 */
@interface IDNFileCache : NSObject

+ (instancetype)sharedCache; ///< 默认的文件缓存器，其本地缓存目录为Library/Caches/IDNFileCache/

@property(nonatomic,readonly) NSString* localCacheDir; ///< 本地缓存目录

/**
 @param localCacheDir 保存缓存文件的本地目录
 */
- (instancetype)initWithLoalCacheDir:(NSString*)localCacheDir;

#pragma mark 从缓存获取

- (NSData*)dataWithKey:(NSString*)key; ///< 根据key获取缓存文件的数据

/** 获取缓存文件的数据
 @param key 缓存文件的key
 @param cacheAge 缓存文件的有效期。0表示永远有效
 @return NSData* 缓存文件的数据。如果文件不存在，或缓存时间超过cacheAge，则返回nil
 */
- (NSData*)dataWithKey:(NSString*)key cacheAge:(NSTimeInterval)cacheAge;

- (BOOL)isFileExistWithKey:(NSString*)key; ///< 检测缓存文件的是否存在

/** 检测缓存文件的是否存在
 @param key 缓存文件的key
 @param cacheAge 缓存文件的有效期。0表示永远有效。如果cacheAge<0，则视为cacheAge==0
 @return BOOL 如果文件存在，并且没有过期，返回YES；否则返回NO
 */
- (BOOL)isFileExistWithKey:(NSString*)key cacheAge:(NSTimeInterval)cacheAge;

#pragma mark 向缓存添加

/** 将指定数据缓存成文件。如果指定key的文件已存在，则覆盖
 @param data 要缓存的数据。
 @param key 缓存文件的key
 */
- (void)cacheFileWithData:(NSData*)data forKey:(NSString*)key;

/** 将一个本地文件放入缓存。如果指定key的文件已存在，则覆盖
 @param filePath 要缓存的文件的本地全路径。缓存成功后此文件将被移除。如果此文件是只读的，则缓存会失败。
 @param key 缓存文件的key
 */
- (void)cacheFileWithPath:(NSString*)filePath forKey:(NSString*)key; //将filePath指定的文件

#pragma mark 删除/清空

- (void)clear; ///< 清空所有缓存文件
- (void)removeFileForKey:(NSString*)key; ///< 根据key删除缓存文件
- (void)removeFilesWithCacheAge:(NSTimeInterval)cacheAge; ///< 删除缓存时间超过cacheAge的所有文件。如果cacheAge==0，相当于clear；如果cacheAge<0，则什么也不会发生
- (void)removeFilesOnBackgroundWithCacheAge:(NSTimeInterval)cacheAge; ///< 使用background task 执行清理工作。建议在applicationDidEnterBackground:方法中调用

@end
