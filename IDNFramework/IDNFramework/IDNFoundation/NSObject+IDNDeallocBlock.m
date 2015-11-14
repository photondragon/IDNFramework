//
//  NSObject+IDNDeallocNote.m
//  IDNFramework
//
//  Created by photondragon on 15/8/26.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "NSObject+IDNDeallocBlock.h"
#import <objc/runtime.h>

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

- (void)dealloc
{
	for (void (^block)() in blocks) {
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

- (void)addDeallocBlock:(void (^)())deallocBlock
{
	if(deallocBlock)
	{
		NSObjectIDNDeallocBlocks* blocks = [self bindedObjectOfNSObjectIDNDeallocBlock];
		if(blocks==nil)
		{
			blocks = [NSObjectIDNDeallocBlocks new];
			[self bindObjectOfNSObjectIDNDeallocBlock:blocks];
		}
		[blocks addBlock:deallocBlock];
	}
}
- (void)delDeallocBlock:(void (^)())deallocBlock
{
	if(deallocBlock)
	{
		NSObjectIDNDeallocBlocks* blocks = [self bindedObjectOfNSObjectIDNDeallocBlock];
		[blocks delBlock:deallocBlock];
	}
}

@end
