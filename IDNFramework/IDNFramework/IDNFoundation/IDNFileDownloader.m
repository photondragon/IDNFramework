//
//  IDNFileDownloader.m
//  IDNFramework
//
//  Created by photondragon on 15/10/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "IDNFileDownloader.h"
#import "IDNTaskQueue.h"
#import "NSPointerArray+IDNExtend.h"

#define SectorSize 4096 //扇区大小

#define TempFilePostfix @".download"

#define UPDATEPROGRESS \
float progress;\
if(_totalLength>0)\
progress = ((double)_downloadedBytes) / _totalLength;\
else \
progress = 0;\
\
if(progress<0)\
progress = 0;\
else if(progress>1.0)\
progress = 1.0;\
\
self.progress = progress;

@interface IDNFileDownloader()
{
	AFHTTPRequestOperation *operation;
	NSURLResponse* response; //如果HTTP请求范围越界，response.statusCode==416，但返回的HTTP body仍会被写入文件，这个body不是要下载的数据
	NSPointerArray* observers;
}
@property(atomic) TKFileDownloadState state;
@property(atomic) float progress;
@property(atomic,strong) NSError* error;
@property(atomic) long long downloadedBytes; //已下载的字节数（也是断点下载的起始位置）
@property(atomic) long long totalLength;

@property(nonatomic) BOOL preparing;
@property(nonatomic) BOOL generating; //是否正在生成AFHTTPRequestOperation

@property(atomic,strong) IDNTaskQueue* backgroundQueue; //后台串行队列
@end

@implementation IDNFileDownloader
@synthesize state=_state;

- (void)dealloc
{
//	NSLog(@"%s", __func__);
	[self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:YES];
//	[self stop];
}

- (instancetype)init
{
	return nil;
}

- (instancetype)initWithUrl:(NSURL*)url savePath:(NSString*)savePath
{
	return [self initWithUrl:url savePath:savePath totalLength:0];
}

- (instancetype)initWithUrl:(NSURL*)url savePath:(NSString*)savePath totalLength:(long long)totalLength;
{
	if(url==nil || savePath.length==0 || totalLength<0)
		return nil;
	
	self = [super init];
	if (self) {
		observers = [NSPointerArray weakObjectsPointerArray];
		_backgroundQueue = [IDNTaskQueue new];
		_url = url;
		_savePath = savePath;
		_totalLength = totalLength;
		self.preparing = YES; //进入准备状态
	}
	return self;
}

- (void)setPreparing:(BOOL)preparing
{
	@synchronized(self)
	{
		if(_preparing==preparing)
			return;
		_preparing = preparing;
		if(_preparing)
		{
			__weak __typeof(self) wself = self;
			[_backgroundQueue performInSequenceQueue:^{
				__typeof(self) sself = wself;
				[sself prepare];
			}];
		}
	}
}

- (void)prepare //在后台线程被调用
{
	NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
	if ([fileManager fileExistsAtPath:_savePath]) { //文件已下载完成
//		DDLogVerbose(@"文件已下：%@", [_savePath lastPathComponent]);
		long long totalLength = [[fileManager attributesOfItemAtPath:_savePath error:nil] fileSize];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self preparedFinishedWithTotalLength:totalLength]; //在主线程更新状态
		});
		return;
	}
	
	// *.download文件
	NSString* tempPath = [_savePath stringByAppendingString:TempFilePostfix];
	long long downloadedBytes = 0;
	if ([fileManager fileExistsAtPath:tempPath])
		downloadedBytes = [[fileManager attributesOfItemAtPath:tempPath error:nil] fileSize];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self preparedWithDownloadedBytes:downloadedBytes]; //在主线程更新状态
	});
}

//在主线程被调用。准备工作完成并且文件事实上已经下载成功
- (void)preparedFinishedWithTotalLength:(long long)totalLength
{
	@synchronized(self)
	{
		self.totalLength = totalLength;
		self.downloadedBytes = totalLength;
		self.progress = 1.0;
		self.preparing = NO;
	}
	[self notifyObserversProgressChanged];
	[self downloadSuccess];
}

//只在主线程被调用。准备工作完成
- (void)preparedWithDownloadedBytes:(long long)downloadedBytes
{
	@synchronized(self)
	{
		self.downloadedBytes = downloadedBytes;
		UPDATEPROGRESS;
		self.preparing = NO;
	}
	[self notifyObserversProgressChanged]; //还没取到totalLength，所以进度为0
	
	@synchronized(self)
	{
		if(_state==TKFileDownloadStateDownloading)
		{
			_generating = YES;
			[_backgroundQueue performInSequenceQueue:^{
				[self generateDownloadOperator];
			}];
		}
	}
}

- (void)start
{
	NSAssert1([NSThread currentThread]==[NSThread mainThread], @"必须在主线程调用%s", __func__);
	
	@synchronized(self)
	{
		if(_state==TKFileDownloadStateDownloading ||
		   _state==TKFileDownloadStateFinished)
			return;
		
		if(self.preparing==NO) // 准备状态已结束（init时会进入准备状态）
		{
			if(operation==nil && _generating==NO)
			{
				_generating = YES;
				[_backgroundQueue performInSequenceQueue:^{
					[self generateDownloadOperator];
				}];
			}
		}
		
		self.state = TKFileDownloadStateDownloading;
	}
	[self notifyObserversStateChangedWithError:nil];
}

// 生成AFHTTPRequestOperation
- (void)generateDownloadOperator
{
	long long startOffset;
	long long totalLength;
	@synchronized(self) {
		startOffset = _downloadedBytes;
		totalLength = _totalLength;
	}
	
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:_url];
	[request setCachePolicy:NSURLRequestReloadIgnoringCacheData]; //不使用缓存，避免断点续传出现问题
	//[[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
	
	BOOL disableSegmentDownload = NO;
	// 获取服务器上文件的基本信息
//	if(totalLength==0)
	{
		request.HTTPMethod = @"HEAD";
		NSString * requestRange = [NSString stringWithFormat:@"bytes=%d-",0];
		[request setValue:requestRange forHTTPHeaderField:@"Range"];
		__block NSURLResponse* resp = nil;
		__block NSError* error;
//		[NSDate measureCode:^{
			[NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&error];
//		} logTitle:@"HEAD elapsedTime="];
		if(error) //错误
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self downLoadFailedWithError:error];
			});
			return;
		}
		else
		{
			NSDictionary* dicHeader = ((NSHTTPURLResponse*)resp).allHeaderFields;
//			DDLogVerbose(@"HEAD %@\n%@", _url, dicHeader);
//			NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//			for (NSHTTPCookie *cookie in [cookieJar cookies]) {
//				NSLog(@"%@", cookie);
//			}
			totalLength = [dicHeader[@"Content-Length"] longLongValue];
			if([dicHeader[@"Accept-Ranges"] isEqualToString:@"bytes"]==NO) //错误。不支持分段下载
			{
				NSString * contentRange = dicHeader[@"Content-Range"];
				if(contentRange.length > 0){
					long long length = [[[contentRange componentsSeparatedByString:@"/"] lastObject] longLongValue];
					if (length > totalLength) {
						totalLength = length;
					}
				}else{
					if(startOffset>0) //已经下载了一部分
					{
						NSFileHandle* h = [NSFileHandle fileHandleForWritingAtPath:_savePath];
						[h truncateFileAtOffset:0]; //清空文件内容
						disableSegmentDownload = YES;
					}
				}
			}
		}
		request.HTTPMethod = @"GET";
		[request setValue:nil forHTTPHeaderField:@"Range"];
	}
	
	BOOL needsNotify = NO;
	@synchronized(self) {
		if(disableSegmentDownload && startOffset>0)
		{
			_downloadedBytes = 0;
			self.progress = 0;
			startOffset = 0;
			needsNotify = YES;
		}
		if(_totalLength != totalLength) // 获得了totalLength
		{
			if(_totalLength!=0)
			{
				;//NSLog(@"%@: 资源大小发生了改变(%lld->%lld), url = %@", NSStringFromClass(self.class), _totalLength, totalLength, _url);
			}
			self.totalLength = totalLength;
			UPDATEPROGRESS;
			needsNotify = YES;
		}
		if(_totalLength>0 && _downloadedBytes>=_totalLength) //已下载完
		{
			if(_downloadedBytes>_totalLength) //可能错误
				;//NSLog(@"%@: 文件已下载部分大于Content-Length指定的大小", NSStringFromClass(self.class));
			[_backgroundQueue performInSequenceQueue:^{
				[self moveDownloadedFile];
			}];
			return;
		}
	}

	if(needsNotify)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self notifyObserversProgressChanged];
		});
	}

	if (startOffset > 0) {
		NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", startOffset];
		[request setValue:requestRange forHTTPHeaderField:@"Range"];
	}
	
	//下载请求
	AFHTTPRequestOperation* op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	op.outputStream = [NSOutputStream outputStreamToFileAtPath:[_savePath stringByAppendingString:TempFilePostfix] append:YES];
	//下载进度回调
	__weak __typeof(self) wself = self;
	[op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
		//下载进度
		[wself bytesRead:bytesRead totalBytesRead:totalBytesRead totalBytesExpectedToRead:totalBytesExpectedToRead];
	}];
	//成功和失败回调
	[op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		__typeof(self) sself = wself;
		[sself.backgroundQueue performInSequenceQueue:^{
			__typeof(self) sself = wself;
			[sself moveDownloadedFile];
		}];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if([error.domain isEqualToString:NSURLErrorDomain] && error.code==NSURLErrorCancelled) //用户停止下载
			return;
		else
			[wself downLoadFailedWithError:error];
	}];
	
	@synchronized(self) {
		_generating = NO;
		if(_state==TKFileDownloadStateStop ||
		   _state==TKFileDownloadStateFinished)
			return;
		operation = op;
		//下载路径
		if(_state==TKFileDownloadStateDownloading)
			[operation start];
	}
}

- (void)bytesRead:(NSUInteger)bytesRead totalBytesRead:(long long)totalBytesRead totalBytesExpectedToRead:(long long)totalBytesExpectedToRead
{
	@synchronized(self)
	{
		if(totalBytesExpectedToRead==-1) //没有Content-Length
		{
//			if(_totalLength)
//			{
//				self.totalLength = 0;
//				;//NSLog(@"%@: 可能没有Content-Length", NSStringFromClass(self.class));
//			}
		}
		else if(_totalLength==0)
			self.totalLength = _downloadedBytes + totalBytesExpectedToRead;
		self.downloadedBytes = _downloadedBytes + bytesRead;
		UPDATEPROGRESS;
	}
	[self notifyObserversProgressChanged];
}

// 在后台线程调用
- (void)moveDownloadedFile
{
	NSError* error;
	if([[NSFileManager defaultManager] moveItemAtPath:[_savePath stringByAppendingString:TempFilePostfix] toPath:_savePath error:&error]==NO)
	{
		;//NSLog(@"移动下载好的文件失败: %@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downLoadFailedWithError:error];
		});
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self downloadSuccess];
		});
	}
}
// 只在主线程调用。
- (void)downloadSuccess
{
	BOOL needsNotityProgress = NO;
	@synchronized(self)
	{
		if(_generating)
			_generating = NO;

		operation = nil;
		if(_downloadedBytes==0 && _totalLength==0)
		{
			self.progress = 1.0; //文件大小就是0
			needsNotityProgress = YES;
		}
		else if(_downloadedBytes != _totalLength) // totalLength不准确
		{
			self.totalLength = _downloadedBytes;
			UPDATEPROGRESS;
			needsNotityProgress = YES;
		}

		self.state = TKFileDownloadStateFinished;
	}
	if(needsNotityProgress)
		[self notifyObserversProgressChanged];
	[self notifyObserversStateChangedWithError:nil];
}

- (void)downLoadFailedWithError:(NSError*)error
{
	;//NSLog(@"%@: %@", NSStringFromClass(self.class), error);
	BOOL needsNotityProgress = NO;
	@synchronized(self)
	{
		if(_generating)
			_generating = NO;
		
		operation = nil;
		self.error = error;
		if(_downloadedBytes != _totalLength) // totalLength不准确
		{
			self.totalLength = _downloadedBytes;
			needsNotityProgress = YES;
		}
		self.state = TKFileDownloadStateStop;
	}
	if(needsNotityProgress)
		[self notifyObserversProgressChanged];
	[self notifyObserversStateChangedWithError:error];
}

- (void)startOrStop
{
	NSAssert1([NSThread currentThread]==[NSThread mainThread], @"必须在主线程调用%s", __func__);
	@synchronized(self) {
		if(_state==TKFileDownloadStateStop)
			[self start];
		else if(//_state==TKFileDownloadStatePause ||
				_state==TKFileDownloadStateDownloading)
			[self stop];
	}
}

- (void)stop
{
	NSAssert1([NSThread currentThread]==[NSThread mainThread], @"必须在主线程调用%s", __func__);
	@synchronized(self) {
		if(_state==TKFileDownloadStateStop ||
		   _state==TKFileDownloadStateFinished)
			return;
		[operation cancel];
		operation = nil;
		self.state = TKFileDownloadStateStop;
	}
	[self notifyObserversStateChangedWithError:nil];
}

- (TKFileDownloadState)state
{
	@synchronized(self) {
		return _state;
	}
}
- (void)setState:(TKFileDownloadState)state
{
	@synchronized(self) {
		if(_state==state)
			return;
		_state = state;
		if(_error && _state!=TKFileDownloadStateStop)
			self.error = nil;
	}
}

#pragma mark Observers

- (void)addFileDownloaderObserver:(id<IDNFileDownloaderObserver>)observer
{
	@synchronized(observers)
	{
		if([observers containsPointer:(__bridge void *)(observer)])//已经是观察者了
			return;
		[observers addPointer:(__bridge void *)(observer)];
	}
}
- (void)delFileDownloaderObserver:(id<IDNFileDownloaderObserver>)observer
{
	@synchronized(observers)
	{
		[observers removePointerIdentically:(__bridge void *)(observer)];
	}
}

- (void)notifyObserversStateChangedWithError:(NSError*)error
{
	BOOL needsCompact = NO;
	// 将当前所有观察者保存到noteObservers中，以免观察者在通知方法里添加或者删除观察者造成死锁
	NSMutableArray* noteObservers = [NSMutableArray new];
	@synchronized(observers)
	{
		for (id<IDNFileDownloaderObserver> observer in observers) {
			if(observer==nil)
			{
				needsCompact = YES;
				continue;
			}
			[noteObservers addObject:observer];
		}
		[observers compact];
	}
	
	for (id<IDNFileDownloaderObserver> observer in noteObservers) {
		if([observer respondsToSelector:@selector(fileDownloaderStateChanged:error:)])
			[observer fileDownloaderStateChanged:self error:error];
	}
}

- (void)notifyObserversProgressChanged
{
	BOOL needsCompact = NO;
	// 将当前所有观察者保存到noteObservers中，以免观察者在通知方法里添加或者删除观察者造成死锁
	NSMutableArray* noteObservers = [NSMutableArray new];
	@synchronized(observers)
	{
		for (id<IDNFileDownloaderObserver> observer in observers) {
			if(observer==nil)
			{
				needsCompact = YES;
				continue;
			}
			[noteObservers addObject:observer];
		}
		[observers compact];
	}
	
	for (id<IDNFileDownloaderObserver> observer in noteObservers) {
		if([observer respondsToSelector:@selector(fileDownloaderProgressChanged:)])
			[observer fileDownloaderProgressChanged:self];
	}
}

@end
