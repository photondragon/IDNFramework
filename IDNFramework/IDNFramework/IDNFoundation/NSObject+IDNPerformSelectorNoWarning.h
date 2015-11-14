//
//  NSObject+IDNPerformSelectorNoWarning.h
//
//  Created by mahj on 15/9/10.
//

#import <Foundation/Foundation.h>

// 普通的performSelector:withObject:方法会产生编译器警告
// 这里提供几个不产生编译器警告的performSelector方法
@interface NSObject(IDNPerformSelectorNoWarning)

- (id)performSelectorNoWarning:(SEL)aSelector;
- (id)performSelectorNoWarning:(SEL)aSelector withObject:(id)object;
- (id)performSelectorNoWarning:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

@end
