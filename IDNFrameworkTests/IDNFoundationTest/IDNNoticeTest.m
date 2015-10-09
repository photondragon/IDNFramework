//
//  IDNNotice.m
//  IDNFramework
//
//  Created by mahj on 15/10/9.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+IDNNotice.h"

@interface IDNNoticeTest : XCTestCase

@end

@implementation IDNNoticeTest
{
	
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)receivedHelloNotice1:(NSString*)text
{
	NSLog(@"%s: %@", __func__, text);
}
- (void)receivedHelloNotice2:(NSString*)text
{
	NSLog(@"%s: %@", __func__, text);
}
- (void)receivedHelloNotice3:(NSString*)text
{
	NSLog(@"%s: %@", __func__, text);
}

- (void)testExample {
	[self subscribeNotice:@"HelloNotice1" subscriber:self selector:@selector(receivedHelloNotice1:)];
	[self subscribeNotice:@"HelloNotice" subscriber:self selector:@selector(receivedHelloNotice2:)];
	[self subscribeNotice:@"HelloNotice" subscriber:self selector:@selector(receivedHelloNotice3:)];
	[self notice:@"HelloNotice1" customInfo:@"world"];
	[self notice:@"HelloNotice" customInfo:@"world"];
	[self unsubscribeNotice:@"HelloNotice" subscriber:self selector:@selector(receivedHelloNotice2:)];
	[self notice:@"HelloNotice1" customInfo:@"jerry"];
	[self notice:@"HelloNotice" customInfo:@"jerry"];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
