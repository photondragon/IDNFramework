//
//  NSObject+IDNCustomObject.m
//  IDNFramework
//
//  Created by photondragon on 15/11/18.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "NSObject+IDNCustomObject.h"
#import <objc/runtime.h>

@implementation NSObject(IDNCustomObject)

static char bindDictionaryKey = 0;

- (NSMutableDictionary*)bindedDictOfNSObjectIDNCustomObject
{
	return objc_getAssociatedObject(self, &bindDictionaryKey);
}
- (NSMutableDictionary*)autoBindedDictOfNSObjectIDNCustomObject
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDictionaryKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDictionaryKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}
- (id)customObjectForKey:(id)aKey
{
	return [self bindedDictOfNSObjectIDNCustomObject][aKey];
}
- (void)setCustomObject:(id)anObject forKey:(id <NSCopying>)aKey
{
	if(anObject==nil || aKey==nil)
		return;
	[[self autoBindedDictOfNSObjectIDNCustomObject] setObject:anObject forKey:aKey];
}
- (void)removeCustomObjectForKey:(id)aKey
{
	[[self bindedDictOfNSObjectIDNCustomObject] removeObjectForKey:aKey];
}

@end
