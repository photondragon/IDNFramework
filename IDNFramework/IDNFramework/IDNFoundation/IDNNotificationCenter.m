//
//  IDNNotificationCenter.m
//  IDNFramework
//
//

#import "IDNNotificationCenter.h"
#import <objc/message.h>
/**
 
 Notification
 
 */

@implementation IDNNotification

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo
{
    if(!name.length){
        return nil;
    }
    self = [super init];
    if(self){
        _name = name;
        _object = object;
        _userInfo = userInfo;
    }
    return self;
}

@end

/**
 
 NotificationObserver
 
 */

@interface NotificationObserver : NSObject

@property (nonatomic,weak) id observer;
@property (nonatomic) SEL selector;
@property (nonatomic,copy) NSString *notificationName;
@property (nonatomic,strong) id object;

- (instancetype)initWithObserver:(id)observer selector:(SEL)selector notificationName:(NSString*)notiName object:(id)object;

@end

@implementation NotificationObserver

- (instancetype)initWithObserver:(id)observer selector:(SEL)selector notificationName:(NSString*)notiName object:(id)object
{
    self = [super init];
    if(self){
        self.observer = observer;
        self.selector = selector;
        self.notificationName = notiName;
        self.object = object;
    }
    return self;
}

@end

/**
 
 NotificationCenter
 
 */

@interface IDNNotificationCenter()
{
    NSMutableArray *list;
    NSLock *lock;
}

@end

@implementation IDNNotificationCenter

+ (IDNNotificationCenter *)defaultCenter
{
    static IDNNotificationCenter* sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if(self){
        lock = [NSLock new];
    }
    return self;
}

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject
{
    if(!observer || !aSelector || !aName.length){
        return;
    }
	if([observer respondsToSelector:aSelector]==NO)
	{
		NSLog(@"%s: %@ 没有 %@ 方法", __func__, NSStringFromClass([observer class]), NSStringFromSelector(aSelector));
		return;
	}
    if(!list){
        list = [NSMutableArray array];
    }
    if(list.count){
        //判断是否存在一个一模一样的观察者
        BOOL needReturn = NO;
        [lock lock];
        for(NotificationObserver *object in list){
            if(object.observer == observer && object.selector==aSelector && [object.notificationName isEqualToString:aName] && object.object == anObject){
                needReturn = YES;
                break;
            }
        }
        [lock unlock];
        if(needReturn){
            return;
        }
    }
    NotificationObserver *observerObject = [[NotificationObserver alloc] initWithObserver:observer selector:aSelector notificationName:aName object:anObject];
    [lock lock];
    [list addObject:observerObject];
    [lock unlock];
}

- (void)postNotification:(IDNNotification *)notification
{
    if(!notification || !notification.name.length){
        return;
    }
    if(!list.count){
        return;
    }
    [lock lock];
    for(NotificationObserver *observerObject in list){
        if([notification.name isEqualToString:observerObject.notificationName] && (observerObject.object==nil || notification.object==observerObject.object)){

			id observer = observerObject.observer;
			SEL aSelector = observerObject.selector;
			IMP imp = [observer methodForSelector:aSelector];
			if(imp==0)
			{
				NSLog(@"%s: error! 方法[%@ %@]不存在", __func__, NSStringFromClass([observer class]), NSStringFromSelector(aSelector));
				return;
			}
			void (*func)(id, SEL, id) = (void *)imp;
			func(observer, aSelector, notification);
			
//			[observerObject.observer performSelector:observerObject.selector withObject:notification];
        }
    }
    [lock unlock];
}
- (void)postNotificationName:(NSString *)aName object:(id)anObject
{
    IDNNotification *notification = [[IDNNotification alloc] initWithName:aName object:anObject userInfo:nil];
    [self postNotification:notification];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
    IDNNotification *notification = [[IDNNotification alloc] initWithName:aName object:anObject userInfo:aUserInfo];
    [self postNotification:notification];
}

- (void)removeObserver:(id)observer
{
	[lock lock];
	for(NSInteger i = list.count-1; i>=0; i--){
		NotificationObserver *object = list[i];
		if(object.observer == observer){
			[list removeObjectAtIndex:i];
		}
	}
	[lock unlock];
}
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject
{
	[lock lock];
	for(NSInteger i = list.count-1; i>=0; i--){
		NotificationObserver *observerInfo = list[i];
		if(observerInfo.observer == observer && [observerInfo.notificationName isEqualToString:aName] && observerInfo.object==anObject){
			[list removeObjectAtIndex:i];
		}
	}
	[lock unlock];
}

@end
