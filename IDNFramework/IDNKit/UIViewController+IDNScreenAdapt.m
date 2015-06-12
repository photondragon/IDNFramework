//
//  UIViewController+IDNScreenAdapt.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIViewController+IDNScreenAdapt.h"

@implementation UIView(IDNScreenAdapt)

+ (NSString*)autoNibName
{
	return [UIView autoNibNameWithViewClassName:NSStringFromClass(self)];
}

+ (NSString*)autoNibNameWithViewClassName:(NSString*)viewClassName
{
	NSString* nibName = nil;
	switch ([UIScreen mainScreenSizeType]) {
		case IDNScreenSizeType55:
			nibName = [NSString stringWithFormat:@"%@-iPhone55",viewClassName];
			break;
		case IDNScreenSizeType47:
			nibName = [NSString stringWithFormat:@"%@-iPhone47",viewClassName];
			break;
		case IDNScreenSizeType40:
			nibName = [NSString stringWithFormat:@"%@-iPhone40",viewClassName];
			break;
		case IDNScreenSizeType35:
			nibName = [NSString stringWithFormat:@"%@-iPhone35",viewClassName];
			break;
		default:
			break;
	}
	if(nibName)
	{
		NSString* path = [[NSBundle mainBundle] pathForResource:nibName ofType:@"nib"];
		if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:0])
		{
			return nibName;
		}
	}
	NSString* path = [[NSBundle mainBundle] pathForResource:viewClassName ofType:@"nib"];
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:0])
	{
		return viewClassName;
	}
	return nil;
}

@end

@implementation UIViewController(IDNScreenAdapt)

+ (NSString*)autoNibName
{
	return [UIView autoNibNameWithViewClassName:NSStringFromClass(self)];
}

@end

