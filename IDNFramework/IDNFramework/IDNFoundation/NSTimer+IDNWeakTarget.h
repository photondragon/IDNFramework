//
//  NSTimer+IDNWeakTarget.h
//  xiangyue
//
//  Created by mahj on 15/8/21.
//  Copyright (c) 2015年 shendou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer(IDNWeakTarget)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;

- (instancetype)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)ti weakTarget:(id)weakTarget selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;

@end
