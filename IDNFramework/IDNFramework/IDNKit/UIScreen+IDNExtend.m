//
//  UIScreen+IDNExtend.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIScreen+IDNExtend.h"

@implementation UIScreen(IDNExtend)

+ (CGFloat)pixelWidth //一个像素宽度
{
	static CGFloat pixelWidth = 0;
	if(pixelWidth==0)
		pixelWidth = 1.0/[UIScreen mainScreen].scale;
	return pixelWidth;
}

+ (IDNScreenSizeType)mainScreenSizeType
{
	static IDNScreenSizeType sizeType = (IDNScreenSizeType)-1;
	if(sizeType==(IDNScreenSizeType)-1)
	{
		CGSize screenSize = [UIScreen mainScreen].bounds.size;
		if(screenSize.width>screenSize.height)
		{
			CGFloat l = screenSize.width;
			screenSize.width = screenSize.height;
			screenSize.height = l;
		}

		if(screenSize.width==320)
		{
			if(screenSize.height==480)
				sizeType = IDNScreenSizeType35;
			else
				sizeType = IDNScreenSizeType40;
		}
		else if(screenSize.width == 375)
		{
			sizeType = IDNScreenSizeType47;
		}
		else if(screenSize.width == 414)
		{
			sizeType = IDNScreenSizeType55;
		}
		else
		{
			sizeType = IDNScreenSizeTypeUnknown;
		}
	}
	return sizeType;
}

@end
