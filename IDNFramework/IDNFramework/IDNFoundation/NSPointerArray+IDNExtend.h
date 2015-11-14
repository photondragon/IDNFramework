//
//  NSPointerArray+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSPointerArray(IDNExtend)

- (void)removePointerIdentically:(void*)pointer;
- (NSUInteger)indexOfPointer:(void*)pointer;
- (BOOL)containsPointer:(void*)pointer;

@end
