
#import "UIAlertView+IDN.h"
#import <objc/runtime.h>

@interface UIAlertViewIDNDelegator : NSObject
<UIAlertViewDelegate>

@end

@implementation UIAlertView (IDN)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfUIAlertViewIDNBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

+ (void)alertWithMessage:(NSString*)message closeHandler:(void (^)())closeHandler
{
	[self alertWithTitle:nil message:message okButtonTitle:@"确定" cancelButtonTitle:nil okHandler:closeHandler cancelHandler:nil];
}

+ (void)alertWithMessage:(NSString*)message okHandler:(void (^)())okHandler cancelHandler:(void (^)())cancelHandler
{
	[self alertWithTitle:nil message:message okButtonTitle:@"确定" cancelButtonTitle:@"取消" okHandler:okHandler cancelHandler:cancelHandler];
}

+ (void)alertWithTitle:(NSString*)title message:(NSString*)message okButtonTitle:(NSString*)okButtonTitle cancelButtonTitle:(NSString*)cancelButtonTitle okHandler:(void (^)())okHandler cancelHandler:(void (^)())cancelHandler
{
	if(okButtonTitle.length==0)
		okButtonTitle = @"确定";
	if(cancelButtonTitle.length==0)
		cancelButtonTitle = nil;
	UIAlertViewIDNDelegator* delegator = [UIAlertViewIDNDelegator new];
	UIAlertView* alertView = [[UIAlertView alloc]
							  initWithTitle:title
							  message:message
							  delegate:delegator
							  cancelButtonTitle:cancelButtonTitle
							  otherButtonTitles:okButtonTitle, nil];
	NSMutableDictionary* dic = [alertView dictionaryOfUIAlertViewIDNBindData];
	if(okHandler)
		dic[@"okHandler"] = okHandler;
	if(cancelButtonTitle && cancelHandler)
		dic[@"cancelHandler"] = cancelHandler;
	dic[@"delegator"] = delegator; //alertView.delegate是assign引用，这里强引用delegator防止其提前释放
	[alertView show];
	return;
	
}

+ (void)alertWithTitle:(NSString*)title message:(NSString*)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:message
												   delegate:nil
										  cancelButtonTitle:@"确定"
										  otherButtonTitles:nil];
	[alert show];
}

+ (void)alertWithError:(NSError*)error
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误"
													message:[error localizedDescription]
												   delegate:nil
										  cancelButtonTitle:@"确定"
										  otherButtonTitles:nil];
	[alert show];
}

@end

@implementation UIAlertViewIDNDelegator

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSMutableDictionary* dic = [alertView dictionaryOfUIAlertViewIDNBindData];
	if(buttonIndex==0)
	{
		void (^cancelHandler)() = dic[@"cancelHandler"];
		if(cancelHandler)
			cancelHandler();
	}
	else
	{
		void (^okHandler)() = dic[@"okHandler"];
		if(okHandler)
			okHandler();
	}
}

@end