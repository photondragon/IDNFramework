//
//  NSObject+IDNCustomObject.h
//  IDNFramework
//
//  Created by photondragon on 15/11/18.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

// 本Category实现可以在任意对象上存储键值对的功能
@interface NSObject(IDNCustomObject)

- (id)customObjectForKey:(id)aKey;
- (void)setCustomObject:(id)anObject forKey:(id <NSCopying>)aKey;
- (void)removeCustomObjectForKey:(id)aKey;

@end
