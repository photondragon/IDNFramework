//
//  IDNAudioPlayer.m
//  MusicPlayer
//
//  Created by mahj on 11/7/13.
//  Copyright (c) 2013年 photondragon. All rights reserved.
//

#import "IDNAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface IDNAudioPlayer()
<AVAudioPlayerDelegate>
{
	AVAudioPlayer* player;
//	NSTimer* updateProgressTimer;
}
@end

@implementation IDNAudioPlayer

+ (instancetype)sharedInstance
{
	static id sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{sharedInstance = [self new];});
	return sharedInstance;
}

- (id)init
{
	self = [super init];
	if(self)
	{
	}
	return self;
}

- (void)dealloc
{
//	updateProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
//	if(updateProgressTimer)
//	{
//		[updateProgressTimer invalidate];
//		updateProgressTimer = nil;
//	}
}

- (void)setAudioFileName:(NSString *)audioFileName
{
	if(_state!=IDNAudioPlayStateNone)
	{
		if(player.isPlaying)
			[player stop];
		player.delegate = nil;
		player = nil;
	}
	
	_audioFileName = audioFileName;
	
	if(_audioFileName)
	{
		NSError* error=nil;
		NSData* data = [NSData dataWithContentsOfFile:audioFileName];
		player = [[AVAudioPlayer alloc] initWithData:data error:&error];
		
		_state = IDNAudioPlayStateNone; //这里不触发状态改变KVO通知
		if(player && error==nil)
		{
			player.delegate = self;
			self.state = IDNAudioPlayStatePlaying;
		}
		else
		{
			self.state = IDNAudioPlayStateStop;
			self.lastError = error;
		}
	}
	else
		self.state = IDNAudioPlayStateNone;
}

- (void)play
{
	if(_state==IDNAudioPlayStateStop)
		self.state = IDNAudioPlayStatePlaying;
}

- (void)stop
{
	if(_state==IDNAudioPlayStatePlaying)
		self.state = IDNAudioPlayStateStop;
}

- (void)playOrStop
{
	if(_state==IDNAudioPlayStatePlaying)
		self.state = IDNAudioPlayStateStop;
	else if(_state==IDNAudioPlayStateStop)
		self.state = IDNAudioPlayStatePlaying;
}

- (void)setState:(IDNAudioPlayState)state
{
	if(_state==state)
		return;
	_state = state;
	if(_state==IDNAudioPlayStatePlaying)
	{
		self.lastError = nil;
		if(player)
			[player play];
		else
		{
			_state = IDNAudioPlayStateStop;
			self.lastError = [NSError errorWithDomain:NSStringFromClass(self.class) code:1 userInfo:@{NSLocalizedDescriptionKey:@"播放器初始化失败"}];
		}
	}
	else if(_state==IDNAudioPlayStateStop)
	{
		if([player isPlaying])
			[player stop];
	}
}

- (double)totalTime
{
	return player.duration;
}
- (double)currentTime
{
	return player.currentTime;
}

- (void)setCurrentTime:(double)currentTime
{
	player.currentTime = currentTime;
//	[self notifyProgressChanged];
}

//- (void)notifyProgressChanged
//{
//	if([_delegate respondsToSelector:@selector(idnAudioPlayerProgressChanged:)])
//		[_delegate idnAudioPlayerProgressChanged:self];
//}

#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)success
{
	self.state = IDNAudioPlayStateStop;
	if(success==NO)
		self.lastError = [NSError errorWithDomain:NSStringFromClass(self.class) code:2 userInfo:@{NSLocalizedDescriptionKey:@"解码错误"}];
	if([_delegate respondsToSelector:@selector(idnAudioPlayer:playbackFinishedWithError:)])
		[_delegate idnAudioPlayer:self playbackFinishedWithError:_lastError];
}

//??????未测试?????
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
	self.state = IDNAudioPlayStateStop;
	self.lastError = error;
}

@end
