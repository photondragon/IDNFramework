//
//  UIColor+IDN.m
//  IDNFramework
//
//  Created by photondragon on 16/1/12.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "UIColor+IDN.h"
#import "NSString+IDNExtend.h"

@implementation UIColor(IDN)

- (UInt32)uint32Value
{
	CGFloat r,g,b,a;
	if([self getRed:&r green:&g blue:&b alpha:&a]==NO)
		return 0;

	UInt32 red = roundf(r*255.0);
	UInt32 green = roundf(g*255.0);
	UInt32 blue = roundf(b*255.0);
	UInt32 alpha = roundf(a*255.0);

	return (red << 24) + (green << 16) + (blue << 8) + alpha;
}

- (NSString *)hexStringRRGGBB
{
	return [NSString stringWithFormat:@"#%.6X", (unsigned int)self.uint32Value>>8];
}
- (NSString *)hexStringRRGGBBAA
{
	return [NSString stringWithFormat:@"#%.8X", (unsigned int)self.uint32Value];
}

#pragma mark - 生成color

+ (UIColor*)colorWithR:(UInt8)r g:(UInt8)g b:(UInt8)b a:(UInt8)a
{
	return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f];
}

+ (UIColor*)colorWithUInt32Value:(UInt32)uint32Value
{
	return [[UIColor alloc] initWithUInt32Value:uint32Value];
}

- (instancetype)initWithUInt32Value:(UInt32)uint32Value
{
	CGFloat red = ((uint32Value & 0xFF000000) >> 24) / 255.0f;
	CGFloat green = ((uint32Value & 0x00FF0000) >> 16) / 255.0f;
	CGFloat blue = ((uint32Value & 0x0000FF00) >> 8) / 255.0f;
	CGFloat alpha = (uint32Value & 0x000000FF) / 255.0f;
	return [self initWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor*)colorWithHex:(NSString*)hexString
{
	if(hexString.length==0)
		return nil;

	float red, green, blue, alpha;

	const char* hex = [hexString trim].UTF8String;
	int len = (int)strlen(hex);
	if(len<3 || len>9)
		return nil;

	if(hex[0]=='#') //有前缀#
	{
		len--;
		hex += 1;
	}

	int values[8];
	for (int i=0; i<len; i++) {
		char c = hex[i];
		if(c>='0' && c<='9')
		{
			values[i] = c - '0';
			continue;
		}
		else if(c>'A' && c<='F')
		{
			values[i] = c - 'A' + 10;
			continue;
		}
		else if(c>'a' && c<='f')
		{
			values[i] = c - 'a' + 10;
			continue;
		}
		else //不是16进制字符串
			return nil;
	}

	if(len==3) //RGB
	{
		red = ((values[0]<<4) + values[1])/255.0;
		green = ((values[1]<<4) + values[1])/255.0;
		blue = ((values[2]<<4) + values[2])/255.0;
		alpha = 1.0;
	}
	else if(len==4) //RGBA
	{
		red = ((values[0]<<4) + values[1])/255.0;
		green = ((values[1]<<4) + values[1])/255.0;
		blue = ((values[2]<<4) + values[2])/255.0;
		alpha = ((values[3]<<4) + values[3])/255.0;
	}
	else if(len==6) //RRGGBB
	{
		red = ((values[0]<<4) + values[1])/255.0;
		green = ((values[2]<<4) + values[3])/255.0;
		blue = ((values[4]<<4) + values[5])/255.0;
		alpha = 1.0;
	}
	else if(len==8) //RRGGBBAA
	{
		red = ((values[0]<<4) + values[1])/255.0;
		green = ((values[2]<<4) + values[3])/255.0;
		blue = ((values[4]<<4) + values[5])/255.0;
		alpha = ((values[6]<<4) + values[7])/255.0;
	}
	else //非法的16进制颜色字符串
		return nil;

	return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor*)blendedColorWithColor:(UIColor *)color factor:(CGFloat)factor
{
	factor = MIN(MAX(factor, 0.0f), 1.0f);

	CGFloat fromRGBA[4], toRGBA[4];
	[self getRGBAComponents:fromRGBA];
	[color getRGBAComponents:toRGBA];

	return [UIColor colorWithRed:fromRGBA[0] + (toRGBA[0] - fromRGBA[0]) * factor
								green:fromRGBA[1] + (toRGBA[1] - fromRGBA[1]) * factor
								 blue:fromRGBA[2] + (toRGBA[2] - fromRGBA[2]) * factor
								alpha:fromRGBA[3] + (toRGBA[3] - fromRGBA[3]) * factor];
}

#pragma mark - component

- (CGFloat)red
{
	CGFloat r;
	if([self getRed:&r green:0 blue:0 alpha:0]==NO)
		return 0;
	return r;
}
- (CGFloat)green
{
	CGFloat g;
	if([self getRed:0 green:&g blue:0 alpha:0]==NO)
		return 0;
	return g;
}
- (CGFloat)blue
{
	CGFloat b;
	if([self getRed:0 green:0 blue:&b alpha:0]==NO)
		return 0;
	return b;
}
- (CGFloat)alpha
{
	CGFloat a;
	if([self getRed:0 green:0 blue:0 alpha:&a]==NO)
		return 0;
	return a;
}

- (CGFloat)hue
{
	CGFloat hue;
	if([self getHue:&hue saturation:0 brightness:0 alpha:0]==NO)
		return 0;
	return hue;
}
- (CGFloat)saturation
{
	CGFloat saturation;
	if([self getHue:0 saturation:&saturation brightness:0 alpha:0]==NO)
		return 0;
	return saturation;
}
- (CGFloat)brightness
{
	CGFloat brightness;
	if([self getHue:0 saturation:0 brightness:&brightness alpha:0]==NO)
		return 0;
	return brightness;
}

- (UInt8)r
{
	CGFloat r;
	if([self getRed:&r green:0 blue:0 alpha:0]==NO)
		return 0;
	return roundf(r*255.0);
}
- (UInt8)g
{
	CGFloat g;
	if([self getRed:0 green:&g blue:0 alpha:0]==NO)
		return 0;
	return roundf(g*255.0);
}
- (UInt8)b
{
	CGFloat b;
	if([self getRed:0 green:0 blue:&b alpha:0]==NO)
		return 0;
	return roundf(b*255.0);
}
- (UInt8)a
{
	CGFloat a;
	if([self getRed:0 green:0 blue:0 alpha:&a]==NO)
		return 0;
	return roundf(a*255.0);
}

- (void)getRGBAComponents:(CGFloat[4])rgba
{
	if(rgba==0)
		return;
	if([self getRed:rgba green:rgba+1 blue:rgba+2 alpha:rgba+3]==NO)
		rgba[0] = rgba[1] = rgba[2] = rgba[3] = 0;
}

#pragma mark - not used

- (BOOL)isMonochromeOrRGB
{
	CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
	return model == kCGColorSpaceModelMonochrome || model == kCGColorSpaceModelRGB;
}

- (void)getRGBAComponents2:(CGFloat[4])rgba
{
	CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
	const CGFloat *components = CGColorGetComponents(self.CGColor);
	switch (model)
	{
		case kCGColorSpaceModelMonochrome:
		{
			rgba[0] = components[0];
			rgba[1] = components[0];
			rgba[2] = components[0];
			rgba[3] = components[1];
			break;
		}
		case kCGColorSpaceModelRGB:
		{
			rgba[0] = components[0];
			rgba[1] = components[1];
			rgba[2] = components[2];
			rgba[3] = components[3];
			break;
		}
		case kCGColorSpaceModelCMYK:
		case kCGColorSpaceModelDeviceN:
		case kCGColorSpaceModelIndexed:
		case kCGColorSpaceModelLab:
		case kCGColorSpaceModelPattern:
		case kCGColorSpaceModelUnknown:
		{

#ifdef DEBUG

			//unsupported format
			NSLog(@"Unsupported color model: %i", model);
#endif
			rgba[0] = 0.0f;
			rgba[1] = 0.0f;
			rgba[2] = 0.0f;
			rgba[3] = 1.0f;
			break;
		}
	}
}

@end
