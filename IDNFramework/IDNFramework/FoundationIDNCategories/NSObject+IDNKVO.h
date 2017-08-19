//
//  NSObject+IDNKVO.h
//  IDNFramework
//
//  Created by photondragon on 16/2/18.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

// 属性绑定（单向）
#define IDNBind(SrcObj, KeyPath1, DstObj, KeyPath2) \
({ \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wreceiver-is-weak\"") \
_Pragma("clang diagnostic ignored \"-Wunused-getter-return-value\"") \
SrcObj.KeyPath1;DstObj.KeyPath2; \
__weak __typeof(DstObj) weakDstObj = (DstObj); \
[SrcObj addKvoBlock:^(id oldValue, id newValue) { \
[weakDstObj setValue:newValue forKeyPath:@#KeyPath2]; \
} forKeyPath:@#KeyPath1]; \
_Pragma("clang diagnostic pop") \
})

/**
 *  此Category用于简化KVO操作
 *  提供target-selector和block两种接口
 *  无需手动删除KVO观察者，会自动删除（在适当时机自动调用removeObserver:forKeyPath:）
 *  但是也可以显式删除KVO观察者
 */
@interface NSObject(IDNKVO)

/**
 *  添加KVO观察者
 *
 *  @param observer 观察者（弱引用）
 *  @param selector 格式: - (void)valueChangedWithOldValue:(id)oldValue newValue:(id)newValue;
 *  @param keyPath
 */
- (void)addKvoObserver:(id)observer
			  selector:(SEL)selector
			forKeyPath:(NSString *)keyPath;
// 删除KVO观察者
- (void)delKvoObserver:(id)observer
			forKeyPath:(NSString *)keyPath;

/**
 *  添加KVO观察者（block版）
 *  慎用，因为如果不手动删除，该block永远不会被删除，可以引起性能降低。
 */
- (void)addKvoBlock:(void (^)(id oldValue, id newValue))block
		 forKeyPath:(NSString *)keyPath;
// 删除KVO观察者（block版）
- (void)delKvoBlock:(void (^)(id oldValue, id newValue))block
			forKeyPath:(NSString *)keyPath;

@end
