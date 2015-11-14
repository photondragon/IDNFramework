
#import <UIKit/UIKit.h>

@interface UIAlertView (IDN)

/**
 显示一条消息+确定按钮
 */
+ (void)alertWithMessage:(NSString*)message closeHandler:(void (^)())closeHandler;

/**
 显示一条消息+确定按钮+取消按钮
 */
+ (void)alertWithMessage:(NSString*)message okHandler:(void (^)())okHandler cancelHandler:(void (^)())cancelHandler;

/**
 显示标题+消息+确定按钮+取消按钮，文本全部可定制
 */
+ (void)alertWithTitle:(NSString*)title message:(NSString*)message okButtonTitle:(NSString*)okButtonTitle cancelButtonTitle:(NSString*)cancelButtonTitle okHandler:(void (^)())okHandler cancelHandler:(void (^)())cancelHandler;

@end
