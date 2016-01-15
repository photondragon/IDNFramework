//
//  IDNFileDownloader.h
//  IDNFramework
//
//  Created by photondragon on 15/10/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, TKFileDownloadState) {
	TKFileDownloadStateStop=0,
	TKFileDownloadStateDownloading,
	TKFileDownloadStateFinished,
//	TKFileDownloadStateFailed, //没有此状态。失败状态 = TKFileDownloadStateStop + error
};

@protocol IDNFileDownloaderObserver;

// 文件断点下载器
@interface IDNFileDownloader : NSObject

@property(nonatomic,copy,readonly) NSURL* url;
@property(nonatomic,copy,readonly) NSString* savePath;

@property(atomic,readonly) TKFileDownloadState state; //当前状态
@property(atomic,readonly) float progress; //下载进度，[0,1.0]之间
@property(atomic,readonly,strong) NSError* error; //下载失败的错误信息，只有在
@property(atomic,readonly) long long downloadedBytes; //已下载的大小
@property(atomic,readonly) long long totalLength; //文件总大小。在下载过程中，可能为0（服务器没有返回Content-Length）

- (instancetype)initWithUrl:(NSURL*)url savePath:(NSString*)savePath;
- (instancetype)initWithUrl:(NSURL*)url savePath:(NSString*)savePath totalLength:(long long)totalLength;

- (void)start;
- (void)stop;
- (void)startOrStop;
//- (void)pause;
//- (void)resume;
//- (void)pauseOrResume;

#pragma mark Observers

- (void)addFileDownloaderObserver:(id<IDNFileDownloaderObserver>)observer;//添加观察者。不会增加observer对象的引用计数，当observer对象引用计数变为0时，会自动删除observer，无需手动删除。
- (void)delFileDownloaderObserver:(id<IDNFileDownloaderObserver>)observer;//删除观察者

@end

@protocol IDNFileDownloaderObserver <NSObject>

@optional

- (void)fileDownloaderProgressChanged:(IDNFileDownloader*)fileDownloader;
- (void)fileDownloaderStateChanged:(IDNFileDownloader*)fileDownloader error:(NSError*)error;
						
@end
