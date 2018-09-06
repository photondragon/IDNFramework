//
//  ViewController.m
//  IDNKitSample
//
//  Created by photondragon on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "ViewController.h"
#import "UIButton+IDNColor.h"
#import "UITextView+IDNExt.h"
#import "UIView+IDNKeyboard.h"

@interface ViewController ()
<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnTestDisable;
@property (weak, nonatomic) IBOutlet UIButton *btnTestHighlight;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
//	self.view.keyboardFrameWillChangeBlock = ^(CGFloat bottomDistance, double animationDuration, UIViewAnimationCurve animationCurve){
//		__typeof(self) sself = wself;
//		[UIView animateWithDuration:animationDuration animations:^{
//			sself.<#constraintBottom#>.constant = bottomDistance;
//			[sself.view layoutIfNeeded];
//		}];
//	};
	self.view.autoResignFirstResponder = YES;

	_btnTestDisable.backgroundColorDisabled = [UIColor lightGrayColor];
	_btnTestDisable.enabled = NO;

	_btnTestHighlight.backgroundColorHighlighted = [UIColor redColor];
	
	_textView.delegate = self; //目前使用上有限制：必须选设置delegate，然后才能设置扩展出来的自定义属性
	_textView.textLimit = 10;
	_textView.acceptCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
//	_textView.acceptCharacterSet = nil;
//	_textView.acceptCharacterSet = [NSCharacterSet decimalDigitCharacterSet];

	_textView.textChangedByUserBlock = ^{
		NSLog(@"text = %@", _textView.text);
	};
	__weak __typeof(self) wself = self;
	_textView.returnPressedBlock = ^{
		__typeof(self) sself = wself;
		[sself.textView resignFirstResponder];
	};
}
- (IBAction)removeTextView:(id)sender {
//	[_textView removeFromSuperview];
}

- (void)textViewDidChange:(UITextView *)textView
{
	NSLog(@"%s", __func__);
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	NSLog(@"%s", __func__);
}

@end
