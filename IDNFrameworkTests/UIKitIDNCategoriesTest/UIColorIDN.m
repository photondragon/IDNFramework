//
//  UIColorIDN.m
//  IDNFramework
//
//  Created by photondragon on 16/3/8.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIColor+IDN.h"

@interface UIColorIDN : XCTestCase

@end

@implementation UIColorIDN

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {

	UIColor* black = [UIColor colorWithHex:@"#000"];
	UIColor* white = [UIColor colorWithHex:@"#FFFF"];
	NSLog(@"black=%@, hex=%@", black, black.hexStringRRGGBB);
	NSLog(@"white=%@, hex=%@", white, white.hexStringRRGGBB);

	UIColor* gray1 = [UIColor colorWithHex:@"#808080"];
	UIColor* gray2 = [black blendedColorWithColor:white factor:0.5];
	NSLog(@"gray1=%@, hex=%@", gray1, gray1.hexStringRRGGBBAA);
	NSLog(@"gray2=%@", gray2);

	UIColor* red1 = [UIColor colorWithHex:@"FF0000ff"];
	UIColor* red2 = [UIColor colorWithHex:red1.hexStringRRGGBBAA];
	NSLog(@"red1=%@, hex=%@", red1, red1.hexStringRRGGBBAA);
	NSLog(@"red2=%@, hex=%@", red2, red2.hexStringRRGGBBAA);

	UIColor* color1 = [UIColor colorWithR:24 g:88 b:222 a:200];
	UIColor* color2 = [UIColor colorWithUInt32Value:color1.uint32Value];
	NSLog(@"color1=%@", color1);
	NSLog(@"color2=%@", color2);
}

@end
