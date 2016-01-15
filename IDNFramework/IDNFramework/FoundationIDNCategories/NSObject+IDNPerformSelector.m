//
//  NSObject+IDNPerformSelector.m
//
//  Created by photondragon on 15/9/10.
//

#import "NSObject+IDNPerformSelector.h"
#import <objc/runtime.h>
#import "NSObject+IDNCustomObject.h"
#import "NSObject+IDNDeallocBlock.h"

@interface NSObject_IDNPerformSelector_WeakTarget : NSObject
@property(nonatomic,weak) id target;
@property(nonatomic) SEL selector;
@property(nonatomic,weak) id anObject;

@property(nonatomic,strong) NSValue* targetKey; //==[NSValue valueWithNonretainedObject:weakTarget]

- (void)performTargetSelectorWithObject:(id)obj;
@end

#pragma mark

@implementation NSObject(IDNPerformSelector)

- (void)performSelectorNoWarning:(SEL)aSelector
{
	[self performSelectorNoWarning:aSelector withObject:nil withObject:nil];
}
- (void)performSelectorNoWarning:(SEL)aSelector withObject:(id)object
{
	[self performSelectorNoWarning:aSelector withObject:object withObject:nil];
}
- (void)performSelectorNoWarning:(SEL)aSelector withObject:(id)object1 withObject:(id)object2
{
	IMP imp = [self methodForSelector:aSelector];
	if(imp==0)
	{
		NSLog(@"[%@ %@]方法不存在", NSStringFromClass([self class]), NSStringFromSelector(aSelector));
		return;
	}
	void (*func)(id, SEL, id, id) = (void *)imp;
	func(self, aSelector, object1, object2);
}

#pragma mark

#define DictWeakTargetsKey @"NSObject+IDNPerformSelector_DictionaryWeakTargets"

#if 0 // log

#ifdef DDLogInfo
#define InnerLog DDLogInfo
#else
#define InnerLog NSLog
#endif

#else

#define InnerLog(...)

#endif

+ (void)NSObject_IDNPerformSelector_registerWeakTarget:(NSObject_IDNPerformSelector_WeakTarget*)weakTarget
{
	NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
	NSMutableDictionary* dicWeakTargets = [currentRunLoop customObjectForKey:DictWeakTargetsKey];
	if(dicWeakTargets==nil)
	{
		dicWeakTargets = [NSMutableDictionary new];
		[currentRunLoop setCustomObject:dicWeakTargets forKey:DictWeakTargetsKey];
	}
	
	NSValue* targetKey = weakTarget.targetKey;
	NSMutableArray* arrayWeakTargets = dicWeakTargets[targetKey];
	if(arrayWeakTargets==nil)
	{
		arrayWeakTargets = [NSMutableArray new];
		dicWeakTargets[targetKey] = arrayWeakTargets;
		
		// 当target对象释放后，从字典中移除target的键（及其相关的所有的weakTargets）
		[weakTarget.target addDeallocBlock:^{
			NSMutableArray* arrayWeakTargets = dicWeakTargets[weakTarget.targetKey];
			if(arrayWeakTargets.count)
			{
				for (NSObject_IDNPerformSelector_WeakTarget*weakTarget in arrayWeakTargets) {
					[NSObject cancelPreviousPerformRequestsWithTarget:weakTarget];
					InnerLog(@"WeakTarget: unregister[%p]", weakTarget);
				}
			}
			[dicWeakTargets removeObjectForKey:targetKey];
			InnerLog(@"WeakTarget: remove TargetKey");
		}];
	}
	[arrayWeakTargets addObject:weakTarget];
	InnerLog(@"WeakTarget: register  [%p]", weakTarget);
}

+ (void)NSObject_IDNPerformSelector_unregisterWeakTarget:(NSObject_IDNPerformSelector_WeakTarget*)weakTarget
{
	NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
	NSMutableDictionary* dicWeakTargets = [currentRunLoop customObjectForKey:DictWeakTargetsKey];
	if(dicWeakTargets==nil)
		return;
	
	NSMutableArray* arrayWeakTargets = dicWeakTargets[weakTarget.targetKey];
	if(arrayWeakTargets==nil)
		return;
	NSInteger oldCount = arrayWeakTargets.count;
	[arrayWeakTargets removeObjectIdenticalTo:weakTarget];
	if(arrayWeakTargets.count!=oldCount)
		InnerLog(@"WeakTarget: unregister[%p]", weakTarget);
}

+ (void)cancelPreviousPerformRequestsWithTargetWeakly:(id)target
{
	NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
	NSMutableDictionary* dicWeakTargets = [currentRunLoop customObjectForKey:DictWeakTargetsKey];
	if(dicWeakTargets==nil)
		return;
	
	NSValue* key = [NSValue valueWithNonretainedObject:target];
	NSMutableArray* arrayWeakTargets = dicWeakTargets[key];
	if(arrayWeakTargets==nil)
		return;

	for (NSObject_IDNPerformSelector_WeakTarget*weakTarget in arrayWeakTargets) {
		[NSObject cancelPreviousPerformRequestsWithTarget:weakTarget];
		InnerLog(@"WeakTarget: unregister[%p]", weakTarget);
	}
	[arrayWeakTargets removeAllObjects];
}

+ (void)cancelPreviousPerformRequestsWithTargetWeakly:(id)target selector:(SEL)selector object:(id)anArgument
{
	NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
	NSMutableDictionary* dicWeakTargets = [currentRunLoop customObjectForKey:DictWeakTargetsKey];
	if(dicWeakTargets==nil)
		return;
	
	NSValue* key = [NSValue valueWithNonretainedObject:target];
	NSMutableArray* arrayWeakTargets = dicWeakTargets[key];
	if(arrayWeakTargets==nil)
		return;

	for (NSInteger i = arrayWeakTargets.count-1; i>=0; i--) {
		NSObject_IDNPerformSelector_WeakTarget*weakTarget = arrayWeakTargets[i];
		if(selector==weakTarget.selector && ((anArgument==weakTarget.anObject) || ([anArgument isEqual:weakTarget.anObject])))
		{
			//每个weakTarget都只会发出一个perform，所以取消时无需区分selector和object
			//[NSObject cancelPreviousPerformRequestsWithTarget:weakTarget selector:@selector(performTargetSelectorWithObject:) object:anArgument];
			[NSObject cancelPreviousPerformRequestsWithTarget:weakTarget];
			[arrayWeakTargets removeObjectAtIndex:i];
			InnerLog(@"WeakTarget: unregister[%p]", weakTarget);
		}
	}
}

- (void)performSelectorWeakly:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay
{
	NSObject_IDNPerformSelector_WeakTarget* weakTarget = [[NSObject_IDNPerformSelector_WeakTarget alloc] init];
	weakTarget.target = self;
	weakTarget.selector = aSelector;
	[NSObject NSObject_IDNPerformSelector_registerWeakTarget:weakTarget];
	
	[weakTarget performSelector:@selector(performTargetSelectorWithObject:) withObject:anArgument afterDelay:delay];
}

- (void)performSelectorWeakly:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray<NSString *> *)modes
{
	NSObject_IDNPerformSelector_WeakTarget* weakTarget = [[NSObject_IDNPerformSelector_WeakTarget alloc] init];
	weakTarget.target = self;
	weakTarget.selector = aSelector;
	[NSObject NSObject_IDNPerformSelector_registerWeakTarget:weakTarget];
	
	[weakTarget performSelector:@selector(performTargetSelectorWithObject:) withObject:anArgument afterDelay:delay inModes:modes];
}

@end

#pragma mark 

@implementation NSObject_IDNPerformSelector_WeakTarget

- (void)setTarget:(id)target
{
	_target = target;
	_targetKey = [NSValue valueWithNonretainedObject:target];
}
- (void)performTargetSelectorWithObject:(id)obj
{
	[_target performSelectorNoWarning:_selector withObject:obj];
	InnerLog(@"WeakTarget: perform...[%p]", self);

	[NSObject NSObject_IDNPerformSelector_unregisterWeakTarget:self];
}
@end

