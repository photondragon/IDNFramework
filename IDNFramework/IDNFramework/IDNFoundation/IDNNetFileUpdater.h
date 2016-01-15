//
//  IDNNetFileUpdater.h
//  IDNFramework
//
//  Created by photondragon on 15/8/20.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

// 网络文件定时更新器（内部会检测304状态，按需更新）。可以用于定时更新配置文件之类的文件
@interface IDNNetFileUpdater : NSObject

+ (instancetype)sharedInstance; // 默认的保存目录是<Library>/IDNNetFileUpdater

- (instancetype)initWithSaveDirectory:(NSString*)directory;

- (void)registerUrl:(NSString*)url updateInterval:(NSTimeInterval)updateInterval forceUpdateOnLaunch:(BOOL)forceUpdateOnLaunch updatedCallback:(void (^)(NSData* data))updatedCallback;
- (void)unregisterUrl:(NSString*)url;
- (NSData*)dataOfUrl:(NSString*)url;

@end
