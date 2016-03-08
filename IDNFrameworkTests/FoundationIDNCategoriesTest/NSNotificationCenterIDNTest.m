//
//  NSNotificationCenterIDNTest.m
//  IDNFramework
//
//  Created by photondragon on 16/3/9.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSNotificationCenter+IDN.h"

#define TestNotification1 @"TestNotification1"
#define TestNotification2 @"TestNotification2"

NSNotificationCenter* notiCenter;

@interface MyNotiCenter : NSNotificationCenter
@end
@implementation MyNotiCenter
- (void)dealloc
{
	NSLog(@"%s", __func__);
}
@end

NSString* lastNotification;

@interface Observer160309 : NSObject

@end
@implementation Observer160309

- (void)dealloc
{
	NSLog(@"%s", __func__);
}

- (void)receiveNoti1:(NSNotification*)noti
{
	lastNotification = noti.name;
	NSLog(@"RECV %@", noti.name);
}
- (void)receiveNoti2:(NSNotification*)noti
{
	lastNotification = noti.name;
	NSLog(@"RECV %@", noti.name);
}

@end

@interface Sender160309 : NSObject

@end
@implementation Sender160309

- (void)dealloc
{
	NSLog(@"%s", __func__);
}

- (void)sendNoti1
{
	if(notiCenter==nil)
		return;
	NSLog(@"SEND %@", TestNotification1);
	[notiCenter postNotificationName:TestNotification1 object:self];
}
- (void)sendNoti2
{
	if(notiCenter==nil)
		return;
	NSLog(@"SEND %@", TestNotification2);
	[notiCenter postNotificationName:TestNotification2 object:self];
}

@end

Observer160309* observer;
Sender160309* sender;

@interface NSNotificationCenterIDNTest : XCTestCase

@end

@implementation NSNotificationCenterIDNTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
	observer = [[Observer160309 alloc] init];
	sender = [[Sender160309 alloc] init];
	notiCenter = [[MyNotiCenter alloc] init];

	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti1:) name:TestNotification1 object:nil];

	[sender sendNoti1];
	XCTAssertEqual(lastNotification, TestNotification1);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	notiCenter = nil;
	observer = nil;
	sender = nil;
}

- (void)testAutoRemoveObserver {
	observer = [[Observer160309 alloc] init];
	sender = [[Sender160309 alloc] init];
	notiCenter = [[MyNotiCenter alloc] init];

	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti1:) name:TestNotification1 object:sender];
	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti2:) name:TestNotification2 object:nil];

	[sender sendNoti1];
	XCTAssertEqual(lastNotification, TestNotification1);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertEqual(lastNotification, TestNotification2);
	lastNotification = nil;

	observer = nil; //提前释放观察者对象

	NSLog(@"SEND %@", TestNotification1);
	[notiCenter postNotificationName:TestNotification1 object:sender];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	notiCenter = nil;
	observer = nil;
	sender = nil;
}

- (void)testAutoRemoveByNotiSenderDealloc {
	observer = [[Observer160309 alloc] init];
	sender = [[Sender160309 alloc] init];
	notiCenter = [[MyNotiCenter alloc] init];

	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti1:) name:TestNotification1 object:sender];
	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti2:) name:TestNotification2 object:nil];

	[sender sendNoti1];
	XCTAssertEqual(lastNotification, TestNotification1);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertEqual(lastNotification, TestNotification2);
	lastNotification = nil;

	sender = nil; //sender释放，会导致TestNotification1的观察者remove，因为添加进带了sender参数。而添加TestNotification2的观察者时没带sender参数

	NSLog(@"SEND %@", TestNotification1);
	[notiCenter postNotificationName:TestNotification1 object:sender];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	NSLog(@"SEND %@", TestNotification2);
	[notiCenter postNotificationName:TestNotification2 object:sender];
	XCTAssertEqual(lastNotification,TestNotification2);
	lastNotification = nil;

	notiCenter = nil;
	observer = nil;
	sender = nil;
}

- (void)testRemoveObserver {
	observer = [[Observer160309 alloc] init];
	sender = [[Sender160309 alloc] init];
	notiCenter = [[MyNotiCenter alloc] init];

	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti1:) name:TestNotification1 object:nil];
	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti2:) name:TestNotification2 object:nil];

	[sender sendNoti1];
	XCTAssertEqual(lastNotification, TestNotification1);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertEqual(lastNotification, TestNotification2);
	lastNotification = nil;

	[notiCenter removeWeakObserver:observer name:TestNotification1 object:nil]; //删除一个观察者1

	[sender sendNoti1];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertEqual(lastNotification, TestNotification2);
	lastNotification = nil;

	notiCenter = nil;
	observer = nil;
	sender = nil;
}

- (void)testRemoveObservers {
	observer = [[Observer160309 alloc] init];
	sender = [[Sender160309 alloc] init];
	notiCenter = [[MyNotiCenter alloc] init];

	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti1:) name:TestNotification1 object:nil];
	[notiCenter addWeakObserver:observer selector:@selector(receiveNoti2:) name:TestNotification2 object:nil];

	[sender sendNoti1];
	XCTAssertEqual(lastNotification, TestNotification1);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertEqual(lastNotification, TestNotification2);
	lastNotification = nil;

	[notiCenter removeWeakObserver:observer]; //删除所有观察者

	[sender sendNoti1];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	[sender sendNoti2];
	XCTAssertNil(lastNotification);
	lastNotification = nil;

	notiCenter = nil;
	observer = nil;
	sender = nil;
}

@end
