//
//  NSPointerArray+IDNExtend.m
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import "NSPointerArray+IDNExtend.h"

@implementation NSPointerArray(IDNExtend)

- (void)removePointerIdentically:(void*)pointer
{
	for (NSInteger i=self.count-1; i>=0; i--) {
		void* p = [self pointerAtIndex:i];
		if(p==pointer)
		{
			[self removePointerAtIndex:i];
			return;
		}
	}
}

- (NSUInteger)indexOfPointer:(void*)pointer
{
	for (NSInteger i=self.count-1; i>=0; i--) {
		void* p = [self pointerAtIndex:i];
		if(p==pointer)
			return i;
	}
	return NSNotFound;
}

- (BOOL)containsPointer:(void*)pointer
{
	for (NSInteger i=self.count-1; i>=0; i--) {
		void* p = [self pointerAtIndex:i];
		if(p==pointer)
			return TRUE;
	}
	return FALSE;
}


@end
