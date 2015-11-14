//
//  NSObject+IDNPerformSelectorNoWarning.m
//
//  Created by mahj on 15/9/10.
//

#import "NSObject+IDNPerformSelectorNoWarning.h"

@implementation NSObject(IDNPerformSelectorNoWarning)

- (id)performSelectorNoWarning:(SEL)aSelector
{
	return [self performSelectorNoWarning:aSelector withObject:nil withObject:nil];
}
- (id)performSelectorNoWarning:(SEL)aSelector withObject:(id)object
{
	return [self performSelectorNoWarning:aSelector withObject:object withObject:nil];
}
- (id)performSelectorNoWarning:(SEL)aSelector withObject:(id)object1 withObject:(id)object2
{
	IMP imp = [self methodForSelector:aSelector];
	if(imp==0)
	{
		NSLog(@"[%@ %@]方法不存在", NSStringFromClass([self class]), NSStringFromSelector(aSelector));
		return nil;
	}
	void (*func)(id, SEL, id, id) = (void *)imp;
	func(self, aSelector, object1, object2);
	return nil;
}

@end
