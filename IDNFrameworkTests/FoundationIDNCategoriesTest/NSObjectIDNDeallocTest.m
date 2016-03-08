//
//  NSObjectIDNDeallocTest.m
//  IDNFramework
//
//  Created by photondragon on 16/3/9.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+IDNDeallocBlock.h"

@interface Object160309 : NSObject

@end
@implementation Object160309

- (void)dealloc
{
	NSLog(@"%s", __func__);
}

@end

BOOL isDeallocBlockCalled;

@interface NSObjectIDNDeallocTest : XCTestCase

@end

@implementation NSObjectIDNDeallocTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
	Object160309* obj = [[Object160309 alloc] init];

	[obj addDeallocBlock:^{
		NSLog(@"obj dealloc block called");
		isDeallocBlockCalled = YES;
	}];

	obj = nil;

	XCTAssertTrue(isDeallocBlockCalled);

	NSLog(@"asdfw");
	isDeallocBlockCalled = NO;
}

@end
