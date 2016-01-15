//
//  UIDevice+IDN.m
//  IDNFramework
//
//  Created by photondragon on 16/1/12.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "UIDevice+IDN.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation UIDevice(IDN)

- (void)idn_setOrientation:(UIInterfaceOrientation)orientation
{
//	if (IOS8_OR_LATER) {
	[self setValue:@(orientation) forKey:@"orientation"];
//	}
//	else
//		[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - 系统音量

static UISlider* volumeViewSlider = nil;

+ (UISlider*)volumeSlider
{
	static MPVolumeView* volumeView = nil;
	if(volumeView==nil)
	{
		volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
		volumeView.backgroundColor = [UIColor redColor];
		volumeView.showsVolumeSlider = NO;
		volumeView.showsRouteButton = NO;
		[[UIApplication sharedApplication].keyWindow addSubview:volumeView];
	}

	if(volumeViewSlider==nil)
	{
		//find the volumeSlider
		for (UIView *view in [volumeView subviews]){
			if ([view isKindOfClass:[UISlider class]]){
				volumeViewSlider = (UISlider*)view;
				volumeView.userInteractionEnabled = YES;
				break;
			}
		}
	}
	return volumeViewSlider;
}

+ (void)setVolume:(CGFloat)volume
{
	[self volumeSlider];

	volumeViewSlider.value = volume;
	[volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

+ (CGFloat)volume
{
//	[self volumeSlider];
//	return volumeViewSlider.value;
	return [AVAudioSession sharedInstance].outputVolume;
}

+ (void)changeVolume:(CGFloat)deltaVolume
{
	if(deltaVolume==0)
		return;
	CGFloat v = [self volume] + deltaVolume;
	if(v<0)
		v = 0;
	else if(v>1.0)
		v = 1.0;
	[self setVolume:v];
}

@end
