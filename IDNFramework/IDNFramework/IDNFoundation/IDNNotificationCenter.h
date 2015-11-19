//
//  IDNNotificationCenter.h
//  IDNFramework
//
//

#import <Foundation/Foundation.h>

#define IDNDefaultNotificationCenter [IDNNotificationCenter defaultCenter]

@interface IDNNotification : NSObject

@property (readonly, strong) NSString *name;
@property (readonly, strong) id object;
@property (readonly, strong) NSDictionary *userInfo;

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;

@end

@interface IDNNotificationCenter : NSObject

+ (IDNNotificationCenter *)defaultCenter;

// 对observer对象是weak型弱引用，对anObject是strong型强引用，如果anObject传入的是nil，那么removeObserver:就不是必须要调用的。
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

- (void)postNotification:(IDNNotification *)notification;
- (void)postNotificationName:(NSString *)aName object:(id)anObject;
- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject;
@end
