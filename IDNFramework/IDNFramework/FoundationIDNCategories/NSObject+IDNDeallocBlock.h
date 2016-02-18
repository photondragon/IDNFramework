//
//  NSObject+IDNDeallocNote.h
//  IDNFramework
//
//  Created by photondragon on 15/8/26.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  实现对象释放的通知机制
 *  注册block，当对象释放时调用。
 *  block内部不能使用self, weakself, strongself
 *  只能使用__unsafe_unretained型self
 *
 *  @code
 *  __unsafe_unretained __typeof(self) uuself = self;
 *  [obj addDeallocBlock:^{
 *		[uuself method];
 *  }];
 *  @endcode
 */
@interface NSObject(IDNDeallocBlock)

/**
 *  添加一个block，在对象的dealloc方法调用前，调用这个block
 *  重复添加同一个Block，实际只会添加一个
 */
- (void)addDeallocBlock:(void (^)())block;
- (void)delDeallocBlock:(void (^)())block;

/**
 * 添加一个block，当对象释放后，调用这个block
 * 重复添加同一个Block，实际只会添加一个
 */
- (void)addDeallocatedBlock:(void (^)())block;
- (void)delDeallocatedBlock:(void (^)())block;

@end
