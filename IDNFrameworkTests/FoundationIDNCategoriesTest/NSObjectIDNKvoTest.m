//
//  NSObjectIDNKvoTest.m
//  IDNFramework
//
//  Created by photondragon on 16/2/18.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+IDNKVO.h"
#import "NSObject+IDNDeallocBlock.h"

BOOL hasSubject = NO;
BOOL hasObserver = NO;

// 被观察者
@interface Subject : NSObject
@property(nonatomic,strong) NSString* name;
@end
@implementation Subject
- (instancetype)init
{
	self = [super init];
	if (self) {
		hasSubject = YES;
	}
	return self;
}
- (void)dealloc
{
	hasSubject = NO;
}
@end

#pragma mark -
@interface Observer : NSObject
@property(nonatomic,strong) NSString* lastOldValue;
@property(nonatomic,strong) NSString* lastNewValue;
@end
@implementation Observer
- (instancetype)init
{
	self = [super init];
	if (self) {
		hasObserver = YES;
	}
	return self;
}
- (void)dealloc
{
	hasObserver = NO;
}

- (void)subjectNameChangedWithOldValue:(id)oldValue newValue:(id)newValue
{
	_lastOldValue = oldValue;
	_lastNewValue = newValue;
}

- (void)clearLastValue
{
	_lastOldValue = nil;
	_lastNewValue = nil;
}

@end

#pragma mark -

BOOL hasController = NO;

@interface Controller : NSObject
@property(nonatomic,strong) NSString* name;
@property(nonatomic,strong) NSString* lastOldValue;
@property(nonatomic,strong) NSString* lastNewValue;
@end
@implementation Controller

- (instancetype)init
{
	self = [super init];
	if (self) {
		hasController = YES;
	}
	return self;
}
- (void)dealloc
{
	hasController = NO;
}

- (void)subjectNameChangedWithOldValue:(id)oldValue newValue:(id)newValue
{
	_lastOldValue = oldValue;
	_lastNewValue = newValue;
}

- (void)clearLastValue
{
	_lastOldValue = nil;
	_lastNewValue = nil;
}

@end

#pragma mark -

@interface NSObjectIDNKvoTest : XCTestCase

@end

@implementation NSObjectIDNKvoTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 基本功能测试--是否能正确观察到值变化
- (void)testFunctionality {
	Subject* subject = [[Subject alloc] init];
	Observer* observer = [[Observer alloc] init];
	XCTAssertTrue(hasSubject, @"Subject对象没有正确创建");
	XCTAssertTrue(hasObserver, @"Observer对象没有正确创建");

	[subject addKvoObserver:observer selector:@selector(subjectNameChangedWithOldValue:newValue:) forKeyPath:@"name"];

	subject.name = @"hello";
	XCTAssertNil(observer.lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"hello", observer.lastNewValue, @"未能正确观察到值变化");
	[observer clearLastValue];

	subject.name = @"world";
	XCTAssertEqual(@"hello", observer.lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"world", observer.lastNewValue, @"未能正确观察到值变化");
	[observer clearLastValue];

	// 测试先释放observer，后释放subject
	observer = nil;
	XCTAssertFalse(hasObserver, @"Observer对象没有释放");
	subject = nil;
	XCTAssertFalse(hasSubject, @"Subject对象没有释放");

	//==========================================================================

	subject = [[Subject alloc] init];
	observer = [[Observer alloc] init];
	[subject addKvoObserver:observer selector:@selector(subjectNameChangedWithOldValue:newValue:) forKeyPath:@"name"];

	// 测试先释放subject，后释放observer
	subject = nil;
	XCTAssertFalse(hasSubject, @"Subject对象没有释放");
	observer = nil;
	XCTAssertFalse(hasObserver, @"Observer对象没有释放");
}

// 基本功能测试（Block版）--是否能正确观察到值变化
- (void)testFunctionality_Block {
	Subject* subject = [[Subject alloc] init];
	XCTAssertTrue(hasSubject, @"Subject对象没有正确创建");

	__block id lastOldValue = nil;
	__block id lastNewValue = nil;
	[subject addKvoBlock:^(id oldValue, id newValue) {
		lastOldValue = oldValue;
		lastNewValue = newValue;
	} forKeyPath:@"name"];

	subject.name = @"hello";
	XCTAssertNil(lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"hello", lastNewValue, @"未能正确观察到值变化");
	lastOldValue = nil;
	lastNewValue = nil;

	subject.name = @"world";
	XCTAssertEqual(@"hello", lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"world", lastNewValue, @"未能正确观察到值变化");
	lastOldValue = nil;
	lastNewValue = nil;

	subject = nil;
	XCTAssertFalse(hasSubject, @"Subject对象没有释放");
}

// 测试删除KVO Observer
- (void)testRemoverObserver
{
	Subject* subject = [[Subject alloc] init];
	Observer* observer = [[Observer alloc] init];

	[subject addKvoObserver:observer selector:@selector(subjectNameChangedWithOldValue:newValue:) forKeyPath:@"name"];
	[subject delKvoObserver:observer forKeyPath:@"name"];

	subject.name = @"hello";
	subject.name = @"world";
	XCTAssertNil(observer.lastOldValue, @"删除观察者后不应该观察到值变化");
	XCTAssertNil(observer.lastNewValue, @"删除观察者后不应该观察到值变化");
	[observer clearLastValue];

	// 测试先释放subject，后释放observer
	subject = nil;
	XCTAssertFalse(hasSubject, @"Subject对象没有释放");
	observer = nil;
	XCTAssertFalse(hasObserver, @"Observer对象没有释放");

	//==========================================================================

	subject = [[Subject alloc] init];

	__block id lastOldValue = nil;
	__block id lastNewValue = nil;
	void (^block)(id oldValue, id newValue) = ^(id oldValue, id newValue) {
		lastOldValue = oldValue;
		lastNewValue = newValue;
	};
	[subject addKvoBlock:block forKeyPath:@"name"];
	[subject delKvoBlock:block forKeyPath:@"name"];

	subject.name = @"hello";
	subject.name = @"world";
	XCTAssertNil(lastOldValue, @"删除观察者后不应该观察到值变化");
	XCTAssertNil(lastNewValue, @"删除观察者后不应该观察到值变化");
	lastOldValue = nil;
	lastNewValue = nil;

	// 测试先释放subject，后释放observer
	subject = nil;
	XCTAssertFalse(hasSubject, @"Subject对象没有释放");
}

// 基本功能测试--观察者与被观察者为同一对象（常见的是Controller对象）
- (void)testFunctionality_selfObserve
{
	//==========================================================================
	//添加-不删除-直接释放

	Controller* controller = [[Controller alloc] init];
	XCTAssertTrue(hasController, @"Controller对象没有正确创建");

	[controller addKvoObserver:controller selector:@selector(subjectNameChangedWithOldValue:newValue:) forKeyPath:@"name"];

	controller.name = @"hello";
	XCTAssertNil(controller.lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"hello", controller.lastNewValue, @"未能正确观察到值变化");
	[controller clearLastValue];

	controller.name = @"world";
	XCTAssertEqual(@"hello", controller.lastOldValue, @"未能正确观察到值变化");
	XCTAssertEqual(@"world", controller.lastNewValue, @"未能正确观察到值变化");
	[controller clearLastValue];

	controller = nil; // 释放controller
	XCTAssertFalse(hasObserver, @"Controller对象没有释放");

	//==========================================================================
	//添加-删除-释放

	controller = [[Controller alloc] init];
	XCTAssertTrue(hasController, @"Controller对象没有正确创建");

	[controller addKvoObserver:controller selector:@selector(subjectNameChangedWithOldValue:newValue:) forKeyPath:@"name"];
	[controller delKvoObserver:controller forKeyPath:@"name"];

	controller = nil; // 释放controller
	XCTAssertFalse(hasObserver, @"Controller对象没有释放");

	//==========================================================================
	//（block版）添加-删除-释放

	controller = [[Controller alloc] init];
	XCTAssertTrue(hasController, @"Controller对象没有正确创建");

	void (^block)(id oldValue, id newValue) = ^(id oldValue, id newValue){

	};
	[controller addKvoBlock:block forKeyPath:@"name"];
	[controller delKvoBlock:block forKeyPath:@"name"];

	controller = nil; // 释放controller
	XCTAssertFalse(hasObserver, @"Controller对象没有释放");
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
