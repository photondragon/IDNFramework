//
//  NSObject+IDNDeallocNote.m
//  IDNFramework
//
//  Created by photondragon on 15/8/26.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSObject+IDNDeallocBlock.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+IDNCustomObject.h"

@interface NSObjectIDNDeallocatedBlocks : NSObject
{
	NSMutableArray* blocks;
}
@end
@implementation NSObjectIDNDeallocatedBlocks

- (instancetype)init
{
	self = [super init];
	if (self) {
		blocks = [NSMutableArray new];
	}
	return self;
}

- (void)addBlock:(void (^)())block
{
	if([blocks indexOfObjectIdenticalTo:block]!=NSNotFound)
		return;
	[blocks addObject:block];
}

- (void)delBlock:(void (^)())block
{
	[blocks removeObjectIdenticalTo:block];
}

- (void)dealloc
{
	for (void (^block)() in blocks) {
		block();
	}
}
@end

@interface NSObjectIDNDeallocBlocks : NSObject
{
	NSMutableArray* blocks;
}
@end
@implementation NSObjectIDNDeallocBlocks

- (instancetype)init
{
	self = [super init];
	if (self) {
		blocks = [NSMutableArray new];
	}
	return self;
}

- (void)addBlock:(void (^)())block
{
	if([blocks indexOfObjectIdenticalTo:block]!=NSNotFound)
		return;
	[blocks addObject:block];
}

- (void)delBlock:(void (^)())block
{
	[blocks removeObjectIdenticalTo:block];
}

- (void)notify
{
	NSEnumerator* enumerator = blocks.objectEnumerator;
	void (^block)();
	while ((block = enumerator.nextObject)) {
		block();
	}
}
@end

@implementation NSObject(IDNDeallocBlock)

static char bindObjectKey = 0;

- (id)bindedObjectOfNSObjectIDNDeallocBlock
{
	return objc_getAssociatedObject(self, &bindObjectKey);
}
- (void)bindObjectOfNSObjectIDNDeallocBlock:(id)obj
{
	objc_setAssociatedObject(self, &bindObjectKey, obj, OBJC_ASSOCIATION_RETAIN);
}

- (void)addDeallocatedBlock:(void (^)())block
{
	if(block==nil)
		return;
	NSObjectIDNDeallocatedBlocks* blocks = [self bindedObjectOfNSObjectIDNDeallocBlock];
	if(blocks==nil)
	{
		blocks = [NSObjectIDNDeallocatedBlocks new];
		[self bindObjectOfNSObjectIDNDeallocBlock:blocks];
	}
	[blocks addBlock:block];
}
- (void)delDeallocatedBlock:(void (^)())block
{
	if(block==nil)
		return;
	NSObjectIDNDeallocatedBlocks* blocks = [self bindedObjectOfNSObjectIDNDeallocBlock];
	[blocks delBlock:block];
}

- (void)addDeallocBlock:(void (^)())block
{
	if(block==nil)
		return;
	NSObjectIDNDeallocBlocks* blocks = [self customObjectForKey:@"NSObject+IDNDeallocBlocks"];
	if(blocks==nil)
	{
		blocks = [NSObjectIDNDeallocBlocks new];
		[self setCustomObject:blocks forKey:@"NSObject+IDNDeallocBlocks"];
		[self idn_swizzleDeallocIfNeeded];
	}
	[blocks addBlock:block];
}

- (void)delDeallocBlock:(void (^)())block;
{
	if(block==nil)
		return;
	NSObjectIDNDeallocBlocks* blocks = [self customObjectForKey:@"NSObject+IDNDeallocBlocks"];
	[blocks delBlock:block];
}

// 此方法参考了ReactiveCocoa中的NSObject(RACDeallocating)
- (void)idn_swizzleDeallocIfNeeded
{
	static dispatch_once_t onceToken;
	static NSMutableSet *swizzledClasses = nil;
	dispatch_once(&onceToken, ^{
		swizzledClasses = [[NSMutableSet alloc] init];
	});
	@synchronized (swizzledClasses)
	{
		Class classToSwizzle = [self class];
		NSString *className = NSStringFromClass(classToSwizzle);
		if ([swizzledClasses containsObject:className])
			return;

		SEL deallocSelector = sel_registerName("dealloc");

		__block void (*oldDeallocImp)(__unsafe_unretained id, SEL) = NULL;

		id newDeallocBlock = ^(__unsafe_unretained id self) {
			//调用dealloc blocks
			NSObjectIDNDeallocBlocks* blocks = [self customObjectForKey:@"NSObject+IDNDeallocBlocks"];
			[blocks notify];

			if (oldDeallocImp == NULL) {
				struct objc_super superInfo = {
					.receiver = self,
					.super_class = class_getSuperclass(classToSwizzle)
				};

				void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
				msgSend(&superInfo, deallocSelector); //调用父类的dealloc
			} else {
				oldDeallocImp(self, deallocSelector); //调用原始dealloc
			}

			//
		};

		IMP newDeallocIMP = imp_implementationWithBlock(newDeallocBlock);

		// 向当前类添加dealloc方法
		BOOL success = class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:");

		if (success==NO) // 当前类重载了dealloc方法，替换
		{
			Method oldDeallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);

			// We need to store original implementation before setting new implementation
			// in case method is called at the time of setting.
			oldDeallocImp = (__typeof__(oldDeallocImp))method_getImplementation(oldDeallocMethod);

			// We need to store original implementation again, in case it just changed.
			oldDeallocImp = (__typeof__(oldDeallocImp))method_setImplementation(oldDeallocMethod, newDeallocIMP);
		}

		[swizzledClasses addObject:className];
	}
}

@end
