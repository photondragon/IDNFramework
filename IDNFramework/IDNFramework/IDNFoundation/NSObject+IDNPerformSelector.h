//
//  NSObject+IDNPerformSelector.h
//
//  Created by photondragon on 15/9/10.
//

#import <Foundation/Foundation.h>

@interface NSObject(IDNPerformSelector)

// 直接调用performSelector:withObject:方法会产生编译器警告
// 这里提供几个不产生编译器警告的performSelector方法
- (void)performSelectorNoWarning:(SEL)aSelector;
- (void)performSelectorNoWarning:(SEL)aSelector withObject:(id)object;
- (void)performSelectorNoWarning:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

// 调用[self performSelector:withObject:afterDelay:]方法会产生一个问题，就是在selector被执行之前，self会被RunLoop强引用，导致self无法及时释放。
// 调用[self performSelectorWeakly:withObject:afterDelay:]只会weak弱引用self
- (void)performSelectorWeakly:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay;
- (void)performSelectorWeakly:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray<NSString *> *)modes;
+ (void)cancelPreviousPerformRequestsWithTargetWeakly:(id)target;
+ (void)cancelPreviousPerformRequestsWithTargetWeakly:(id)target selector:(SEL)selector object:(id)anArgument;

@end
