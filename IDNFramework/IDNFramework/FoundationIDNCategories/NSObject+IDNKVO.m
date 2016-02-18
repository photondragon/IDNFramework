//
//  NSObject+IDNKVO.m
//  IDNFramework
//
//  Created by photondragon on 16/2/18.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import "NSObject+IDNKVO.h"
#import "NSObject+IDNCustomObject.h"
#import "NSObject+IDNDeallocBlock.h"

@interface IDNKVOObserver : NSObject
@property(nonatomic,unsafe_unretained,readonly) id observedObject; //必须是__unsafe_unretained
@property(nonatomic,strong,readonly) NSString* keyPath;
@property(nonatomic,strong,readonly) void (^action)(id oldValue, id newValue);
@end

@implementation IDNKVOObserver

- (id)initWithObservedObj:(id)observedObj
				  keyPath:(NSString*)keyPath
				 observer:(id)observer
				 selector:(SEL)selector
{
	if(observer==nil)
		return nil;

	__weak id weakObserver = observer;
	void (^action)(id oldValue, id newValue) = ^(id oldValue, id newValue){
		id strongObserver = weakObserver;
		if ([strongObserver respondsToSelector:selector])
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[strongObserver performSelector:selector withObject:oldValue withObject:newValue];
#pragma clang diagnostic pop
		}
	};

	return [self initWithObservedObj:observedObj keyPath:keyPath action:action];
}

- (instancetype)initWithObservedObj:(id)observedObj
							keyPath:(NSString*)keyPath
							 action:(void (^)(id oldValue, id newValue))action
{
	if(action==nil)
		return nil;

	self = [super init];
	if (self) {
		_observedObject = observedObj;
		_keyPath = keyPath;
		_action = action;
		[observedObj addObserver:self
					  forKeyPath:keyPath
						 options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
						 context:NULL];
	}
	return self;
}

- (void)dealloc
{
	[_observedObject removeObserver:self forKeyPath:_keyPath];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	id oldValue = change[NSKeyValueChangeOldKey];
	id newValue = change[NSKeyValueChangeNewKey];
	if([oldValue isKindOfClass:[NSNull class]])
		oldValue =  nil;
	if([newValue isKindOfClass:[NSNull class]])
		newValue =  nil;
	self.action(oldValue, newValue);
}

@end

@implementation NSObject(IDNKVO)

- (void)inner_addKvoObserver:(IDNKVOObserver*)kvoObserver bindKey:(NSString*)bindKey
{
	[self setCustomObject:kvoObserver forKey:bindKey];
	__unsafe_unretained __typeof(self) uuself = self;
	void (^deallocBlock)() = ^{
		[uuself removeCustomObjectForKey:bindKey];
	};
	[self addDeallocBlock:deallocBlock];
}

- (void)addKvoObserver:(id)observer
			  selector:(SEL)selector
			forKeyPath:(NSString *)keyPath
{
	if(observer==nil || keyPath.length==0)
		return;
	keyPath = [keyPath copy];

	NSString* bindKey = [NSString stringWithFormat:@"IDNKVO:observer=%p,keyPath=%@", observer, keyPath];
	IDNKVOObserver* kvoObserver = [[IDNKVOObserver alloc] initWithObservedObj:self keyPath:keyPath observer:observer selector:selector];
	[self inner_addKvoObserver:kvoObserver bindKey:bindKey];

	__unsafe_unretained __typeof(self) uuself = self;
	[observer addDeallocBlock:^{
		[uuself removeCustomObjectForKey:bindKey];
	}];
}

- (void)delKvoObserver:(id)observer
			forKeyPath:(NSString *)keyPath
{
	if(observer==nil || keyPath.length==0)
		return;

	NSString* bindKey = [NSString stringWithFormat:@"IDNKVO:observer=%p,keyPath=%@", observer, keyPath];
	[self removeCustomObjectForKey:bindKey];
}

- (void)addKvoBlock:(void (^)(id oldValue, id newValue))block
		 forKeyPath:(NSString *)keyPath
{
	if(block==nil || keyPath.length==0)
		return;
	keyPath = [keyPath copy];

	NSString* bindKey = [NSString stringWithFormat:@"IDNKVO:block=%p,keyPath=%@", block, keyPath];
	IDNKVOObserver* kvoObserver = [[IDNKVOObserver alloc] initWithObservedObj:self keyPath:keyPath action:block];
	[self inner_addKvoObserver:kvoObserver bindKey:bindKey];
}

- (void)delKvoBlock:(void (^)(id oldValue, id newValue))block
			forKeyPath:(NSString *)keyPath
{
	if(block==nil || keyPath.length==0)
		return;

	NSString* bindKey = [NSString stringWithFormat:@"IDNKVO:block=%p,keyPath=%@", block, keyPath];
	[self removeCustomObjectForKey:bindKey];
}

@end
