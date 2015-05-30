//
//  UIScreen+IDNSizeType.h
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIScreen+IDNSizeType.h"

@implementation UIScreen(IDNSizeType)

+ (ScreenSizeType)mainScreenSizeType
{
	static ScreenSizeType sizeType = (ScreenSizeType)-1;
	if(sizeType==(ScreenSizeType)-1)
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
				sizeType = ScreenSizeType35;
			else
				sizeType = ScreenSizeType40;
		}
		else if(screenSize.width == 375)
		{
			sizeType = ScreenSizeType47;
		}
		else if(screenSize.width == 414)
		{
			sizeType = ScreenSizeType55;
		}
		else
		{
			sizeType = ScreenSizeTypeUnknown;
		}
	}
	return sizeType;
}

@end
