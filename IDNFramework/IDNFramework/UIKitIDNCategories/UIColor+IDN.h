//
//  UIColor+IDN.h
//  IDNFramework
//
//  Created by photondragon on 16/1/12.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(IDN)

@property(nonatomic,readonly) UInt32 uint32Value; //颜色的UInt32值（从高位到低位依次是RGBA），可以用于持久化存储

- (NSString*)hexStringRRGGBB; //#RRGGBB
- (NSString*)hexStringRRGGBBAA; //#RRGGBBAA

#pragma mark 生成color

+ (UIColor*)colorWithR:(UInt8)r g:(UInt8)g b:(UInt8)b a:(UInt8)a; //r,g,b,a取值范围[0,255]
+ (UIColor*)colorWithUInt32Value:(UInt32)uint32Value; //uint32Value是颜色的UInt32值（从高位到低位依次是RGBA）
+ (UIColor*)colorWithHex:(NSString*)hexString; //hexString为颜色的16进制字符串，格式可以是@"#RRGGBB"、@"#RRGGBBAA"、@"#RGB"或@"#RGBA"，前缀#可选

- (UIColor*)blendedColorWithColor:(UIColor*)color factor:(CGFloat)factor; //与参数color指定颜色混合，返回混合后的颜色。factor为color的比例，取值[0,1.0];

#pragma mark component

@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;
@property (nonatomic, readonly) CGFloat alpha;

@property (nonatomic, readonly) CGFloat hue;
@property (nonatomic, readonly) CGFloat saturation;
@property (nonatomic, readonly) CGFloat brightness;

@property (nonatomic, readonly) UInt8 r;
@property (nonatomic, readonly) UInt8 g;
@property (nonatomic, readonly) UInt8 b;
@property (nonatomic, readonly) UInt8 a;

- (void)getRGBAComponents:(CGFloat[4])rgba; //返回的数组

@end
