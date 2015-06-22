//
//  IDNFileCacheTest.m
//  IDNFramework
//
//  Created by photondragon on 15/6/22.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSString+IDNExtend.h"
#import "NSData+IDNExtend.h"
#import "IDNFileCache.h"

@interface IDNFileCacheTest : XCTestCase

@end

@implementation IDNFileCacheTest
{
	NSString* fileName1; //立即以Data缓存
	NSString* fileName2; //立即以文件缓存
	NSString* fileName3; //4秒后以Data缓存
	NSString* fileName4; //4秒后以文件缓存
	NSData* fileData1;
	NSData* fileData2;
	NSData* fileData3;
	NSData* fileData4;

	IDNFileCache* cache;

}
- (void)setUp {
    [super setUp];
    fileName1 = @"fileName1";
	fileName2 = @"fileName2";
	fileName3 = @"fileName3";
	fileName4 = @"fileName4";

	fileData1 = [fileName1 dataUsingEncoding:NSUTF8StringEncoding];
	fileData2 = [fileName2 dataUsingEncoding:NSUTF8StringEncoding];
	fileData3 = [fileName3 dataUsingEncoding:NSUTF8StringEncoding];
	fileData4 = [fileName4 dataUsingEncoding:NSUTF8StringEncoding];

	[fileData2 writeToDocumentFile:fileName2];
	[fileData4 writeToDocumentFile:fileName4];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)cacheOperations
{
	//fileName1立即以Data缓存
	[cache cacheFileWithData:fileData1 forKey:fileName1];

	XCTAssertTrue([cache isFileExistWithKey:fileName1], @"缓存文件失败，找不到缓存文件key=%@", fileName1);

	XCTAssertTrue([[cache dataWithKey:fileName1] isEqualToData:fileData1], @"读取缓存文件内容失败，key=%@", fileName1);

	//fileName2立即以文件缓存
	[cache cacheFileWithPath:[NSString documentsPathWithFileName:fileName2] forKey:fileName2];

	XCTAssertTrue([cache isFileExistWithKey:fileName2], @"缓存文件失败，找不到缓存文件key=%@", fileName2);

	XCTAssertTrue([[cache dataWithKey:fileName2] isEqualToData:fileData2], @"读取缓存文件内容失败，key=%@", fileName2);

	XCTestExpectation *expectBackgroundCache = [self expectationWithDescription:@"expect background cache"];

	// 在后台线程cache
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		///////睡眠4秒///////
		sleep(3);

		//fileName3 4秒后以Data缓存
		[cache cacheFileWithData:fileData3 forKey:fileName3];

		XCTAssertTrue([cache isFileExistWithKey:fileName3], @"缓存文件失败，找不到缓存文件key=%@", fileName3);

		XCTAssertTrue([[cache dataWithKey:fileName3] isEqualToData:fileData3], @"读取缓存文件内容失败，key=%@", fileName3);

		//fileName4 4秒后以文件缓存
		[cache cacheFileWithPath:[NSString documentsPathWithFileName:fileName4] forKey:fileName4];

		XCTAssertTrue([cache isFileExistWithKey:fileName4], @"缓存文件失败，找不到缓存文件key=%@", fileName4);

		XCTAssertTrue([[cache dataWithKey:fileName4] isEqualToData:fileData4], @"读取缓存文件内容失败，key=%@", fileName4);

		[expectBackgroundCache fulfill];
	});

	[self waitForExpectationsWithTimeout:4 handler:nil];
	
	XCTAssertFalse([cache isFileExistWithKey:fileName1 cacheAge:2], @"缓存过期仍能检测到缓存文件的存在，key=%@", fileName1);

	XCTAssertNil([cache dataWithKey:fileName1 cacheAge:2], @"缓存过期仍能读取到缓存文件，key=%@", fileName1);

	XCTAssertFalse([cache isFileExistWithKey:fileName2 cacheAge:2], @"缓存过期仍能检测到缓存文件的存在，key=%@", fileName2);

	XCTAssertNil([cache dataWithKey:fileName2 cacheAge:2], @"缓存过期仍能读取到缓存文件，key=%@", fileName2);

	//删除/清空测试

	[cache removeFileForKey:fileName3];
	XCTAssertFalse([cache isFileExistWithKey:fileName3], @"-[IDNFileCache removeFileForKey:]删除指定缓存文件失败，key=%@", fileName3);

	[cache removeFilesWithCacheAge:3];
	XCTAssertFalse([cache isFileExistWithKey:fileName1], @"-[IDNFileCache removeFilesWithCacheAge:]过期文件未删除，key=%@", fileName1);
	XCTAssertFalse([cache isFileExistWithKey:fileName2], @"-[IDNFileCache removeFilesWithCacheAge:]过期文件未删除，key=%@", fileName2);
	XCTAssertTrue([cache isFileExistWithKey:fileName4], @"-[IDNFileCache removeFilesWithCacheAge:]未过期文件被错误删除，key=%@", fileName4);

	XCTestExpectation* expectBackgroundClear = [self expectationWithDescription:@"expect background clear"];
	// 在后台线程clear
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[cache clear];
		[expectBackgroundClear fulfill];
	});
	[self waitForExpectationsWithTimeout:1.0 handler:nil];

	XCTAssertFalse([cache isFileExistWithKey:fileName4], @"-[IDNFileCache clear]未能清空缓存，key=%@", fileName4);
	
	cache = nil;
}
- (void)testSharedCache {
	cache = [IDNFileCache sharedCache];
	XCTAssert(cache.localCacheDir.length, @"[IDNFileCache sharedCache] 创建失败");

	[self cacheOperations];
}
- (void)testCustomCache {
	cache = [[IDNFileCache alloc] initWithLoalCacheDir:[NSString documentsPath]];
	XCTAssert(cache.localCacheDir.length, @"[IDNFileCache sharedCache] 创建失败");

	[self cacheOperations];
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
