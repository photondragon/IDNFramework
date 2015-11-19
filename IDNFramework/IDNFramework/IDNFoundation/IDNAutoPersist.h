//
//  IDNAutoPersist.h
//  IDNFramework
//
//  Created by photondragon on 15/8/5.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDNAutoPersist : NSObject

+ (instancetype)defaultPersister;

- (instancetype)initWithPersistPath:(NSString*)path;
- (void)setNeedSaving;

@property (readonly) NSUInteger count;
- (id)objectForKey:(id)aKey;
- (NSArray*)allKeys;
- (NSArray *)allKeysForObject:(id)anObject;
- (NSArray*)allValues;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;
- (void)removeObjectsForKeys:(NSArray *)keyArray;
- (void)setDictionary:(NSDictionary *)otherDictionary;
- (void)removeAllObjects;

@end
