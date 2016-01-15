//
//  NSObject+IDNDeallocNote.h
//  IDNFramework
//
//  Created by photondragon on 15/8/26.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(IDNDeallocBlock)

/**
 添加一个block，当对象释放时，调用这个block
 重复添加同一个Block，实际只会添加一个
 block的调用时机是在[self dealloc]之后，对象实际释放之前
 也就是说在block内部仍然可以访问self对象，要注意的是有些资源可能在之前的dealloc中被释放了
 绝对不能在Block中直接使用self，weakself, strongself也不能用。
 只能用__unsafe_unretained __typeof(self) uuself = self;
 */
- (void)addDeallocBlock:(void (^)())block;
- (void)delDeallocBlock:(void (^)())block;

@end
