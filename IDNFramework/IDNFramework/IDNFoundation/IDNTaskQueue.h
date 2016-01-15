//
//  IDNTaskQueue.h
//  IDNFramework
//
//  Created by photondragon on 15/10/20.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDNTaskQueue : NSObject

- (void)performInSequenceQueue:(void (^)())taskBlock;

@end
