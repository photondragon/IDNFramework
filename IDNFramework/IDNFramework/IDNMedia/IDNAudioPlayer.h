//
//  IDNAudioPlayer.h
//  MusicPlayer
//
//  Created by mahj on 11/7/13.
//  Copyright (c) 2013年 photondragon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger)
{
	IDNAudioPlayStateNone=0,//未加载
	IDNAudioPlayStatePlaying,//正在播放
	IDNAudioPlayStateStop,//停止
}IDNAudioPlayState;

/// 声音播放器委托
@protocol IDNAudioPlayerDelegate;

@interface IDNAudioPlayer : NSObject

+ (instancetype)sharedInstance;

- (void)play;
- (void)stop;
- (void)playOrStop;

@property(nonatomic,strong) id<IDNAudioPlayerDelegate> delegate;

@property(nonatomic,strong) NSString* audioFileName;

@property(nonatomic) IDNAudioPlayState state;
@property(nonatomic,strong) NSError* lastError;

@property(nonatomic) double currentTime;//当前播放位置（时间）
@property(nonatomic,readonly) double duration;//总时长

@end

@protocol IDNAudioPlayerDelegate <NSObject>
@optional

- (void)idnAudioPlayer:(IDNAudioPlayer*)player playbackFinishedWithError:(NSError*)error; //播放结束. 如果是中途调用stop, 则不会触发playbackFinished
//- (void)idnAudioPlayerProgressChanged:(IDNAudioPlayer*)player;

@end
