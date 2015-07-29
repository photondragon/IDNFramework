//
//  IDNInputHelperView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNInputHelperView.h"

@interface InputHelperContentView : UIView
@end
@implementation InputHelperContentView
- (void)didAddSubview:(UIView *)subview;
{
	[self.superview didAddSubview:subview];
}
- (void)willRemoveSubview:(UIView *)subview
{
	[self.superview willRemoveSubview:subview];
}
@end

@interface InputHelperInputViewInfo : NSObject
@property (nonatomic,assign) UITextField* textField;
@end
@implementation InputHelperInputViewInfo
@synthesize textField;
- (NSComparisonResult)compare:(InputHelperInputViewInfo *)another
{
	float y = textField.frame.origin.y;
	float anotherY = another.textField.frame.origin.y;
	if(y < anotherY)
		return NSOrderedAscending;
	else if(y > anotherY)
		return NSOrderedDescending;
	return NSOrderedSame;
}
@end

@interface IDNInputHelperView()
<UITextViewDelegate>
@end

@implementation IDNInputHelperView
{
	float maxScrollY;//等于键盘顶到InputHelperView底部的距离。当没有键盘时，此值为0.
	float curScrollY;
	UIView* currentTextField;//assign
	NSMutableArray* arrayInputViewInfos;
	UIView* contentView;
	NSTimeInterval animationDuration;
	BOOL isTouchMoved;
	CGPoint touchPos;
}
- (void)initialize
{
	if(arrayInputViewInfos)
		return;
	arrayInputViewInfos = [[NSMutableArray alloc] init];
	contentView = [[InputHelperContentView alloc] initWithFrame:self.bounds];
	contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	[self addSubview:contentView];
}

- (id)init
{
	self = [super init];
	if(self)
	{
		[self initialize];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		[self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self)
	{
		[self initialize];
	}
	return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	if(newWindow)
	{
#ifdef __IPHONE_5_0
		float version = [[[UIDevice currentDevice] systemVersion] floatValue];
		if (version >= 5.0)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
			return;//当键盘出现时，既会触发WillShowNotification，也会触发WillChangeFrameNotification
		}
#endif
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillHideNotification object:nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	}
}

- (UIColor*)backgroundColor
{
	if(contentView==nil)
		[self initialize];
	return contentView.backgroundColor;
}
- (void)setBackgroundColor:(UIColor *)backgroundColor
{
	if(contentView==nil)
		[self initialize];
	contentView.backgroundColor = backgroundColor;
}
- (void)addSubview:(UIView *)view
{
	if(contentView==nil)
		[self initialize];
	if(view==contentView)
	{
		[super addSubview:view];//添加内容VIEW
		return;
	}
	[contentView addSubview:view];//所有的子View全都加入contentView内
}
- (void)didAddSubview:(UIView *)subview;
{
	//if([subview isKindOfClass:[UITextField class]])//如果是输入框
	if([subview conformsToProtocol:@protocol(UITextInput)])//如果是输入框
	{
		if([subview isKindOfClass:[UITextField class]])
		{
			[((UITextField*)subview) addTarget:self action:@selector(textFieldBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
			[((UITextField*)subview) addTarget:self action:@selector(textFieldEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
		}
		else if([subview isKindOfClass:[UITextView class]])
		{
			[(UITextView*)subview setDelegate:self];
		}
		else
			return;
		InputHelperInputViewInfo* info = [[InputHelperInputViewInfo alloc] init];
		info.textField = (UITextField*)subview;
		[arrayInputViewInfos addObject:info];
		[arrayInputViewInfos sortUsingSelector:@selector(compare:)];
	}
}
- (void)willRemoveSubview:(UIView *)subview;
{
	if([subview isKindOfClass:[UITextField class]])//如果是输入框
	{
		if([subview isKindOfClass:[UITextField class]])
		{
			[((UITextField*)subview) removeTarget:self action:@selector(textFieldBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
			[((UITextField*)subview) removeTarget:self action:@selector(textFieldEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
		}
		else if([subview isKindOfClass:[UITextView class]])
		{
			[(UITextView*)subview setDelegate:nil];
		}
		else
			return;
		InputHelperInputViewInfo* info;
		for (NSInteger i=arrayInputViewInfos.count-1;i>=0;i--)
		{
			info =(InputHelperInputViewInfo*)[arrayInputViewInfos objectAtIndex:i];
			if(info.textField==subview)
				[arrayInputViewInfos removeObjectAtIndex:i];
		}
	}
}

- (void)scrollTo:(float)scrollY duration:(float)duration
{
//	if (scrollY<0)
//		scrollY = 0;
//	else if(scrollY>maxScrollY)
//		scrollY = maxScrollY;
	if(scrollY==curScrollY)
		return;
	
	curScrollY = scrollY;
	
	CGRect rect = self.bounds;
    rect.origin.y = -curScrollY;
	
	if(duration>0)
	{
  	  [UIView beginAnimations:nil context:NULL];
  	  [UIView setAnimationDuration:duration];
    }
    contentView.frame = rect;
	
	if(duration>0)
	    [UIView commitAnimations];
}
- (void)adjustContent
{
	//static int times = 0;
	//NSLog(@"***%02d***adjustContent",++times);
	CGRect rect = self.bounds;
	float visibleHeight = rect.size.height - maxScrollY;
	float scrollY;
	if(maxScrollY==0)
		scrollY = 0;
	else
	{
		CGRect textRect1 = currentTextField.frame;
		float start = textRect1.origin.y;
		float end = start + textRect1.size.height;
		//
		for (int i=0; i<arrayInputViewInfos.count; i++)
		{
			InputHelperInputViewInfo* info = (InputHelperInputViewInfo*)[arrayInputViewInfos objectAtIndex:i];
			if (info.textField==currentTextField)
			{
				int j=i+1;
				if(j<arrayInputViewInfos.count)
				{//当前textField下方的一个textField
					InputHelperInputViewInfo* info2 = (InputHelperInputViewInfo*)[arrayInputViewInfos objectAtIndex:j];
					CGRect textRect2 = info2.textField.frame;
					float start2 = textRect2.origin.y;
					float end2 = start2 + textRect2.size.height;
					if(start2<start)
						start = start2;//不应该执行这行
					if(end2>end)
						end = end2;
				}
				j=i-1;
				if(j>=0)
				{//当前textField上方的一个textField
					InputHelperInputViewInfo* info2 = (InputHelperInputViewInfo*)[arrayInputViewInfos objectAtIndex:j];
					CGRect textRect2 = info2.textField.frame;
					float start2 = textRect2.origin.y;
					float end2 = start2 + textRect2.size.height;
					if(start2<start)
						start = start2;
					if(end2>end)
						end = end2;
				}
			}
		}
		if(end-start>visibleHeight)//可视区域太小，容不下textField;
		{
			scrollY = start + (end-start)/2.0 - visibleHeight/2.0;
		}
		else
		{
			if(start<curScrollY)
				scrollY = start;
			else if(end-curScrollY>visibleHeight)
				scrollY = end - visibleHeight;
			else
				scrollY = curScrollY;
		}
	}
    [self scrollTo:scrollY duration:animationDuration];
}

- (void) textFieldBeginEditing:(id)sender
{
	//NSLog(@"[%p]begin editing",sender);
	currentTextField = sender;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(adjustContent) object:nil];
	[self performSelector:@selector(adjustContent) withObject:nil afterDelay:0];
}
- (void) textFieldEndEditing:(id)sender
{
	//NSLog(@"[%p]end editing",sender);
	currentTextField = nil;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(adjustContent) object:nil];
	[self performSelector:@selector(adjustContent) withObject:nil afterDelay:0];
}

#pragma mark - Responding to keyboard events

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
 	//NSLog(@"keyboard ChangeFrame");
    NSDictionary *userInfo = [notification userInfo];
    
    NSNumber *animationDurationNumber = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    animationDuration = [animationDurationNumber doubleValue];
    
	CGRect rect = self.bounds;
	NSValue *keyboardFrameValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardFrameValue CGRectValue];
	if(keyboardRect.size.height==0)
		maxScrollY = 0;
	else
	{
	    keyboardRect = [self convertRect:keyboardRect fromView:nil];//由屏幕坐标转为view的坐标
		CGFloat keyboardTop = keyboardRect.origin.y;
		maxScrollY = rect.size.height - keyboardTop;
		if (maxScrollY<0)
			maxScrollY = 0;
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(adjustContent) object:nil];
	[self performSelector:@selector(adjustContent) withObject:nil afterDelay:0];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	isTouchMoved = FALSE;
	UITouch* touch = [touches anyObject];
	touchPos = [touch locationInView:self];
	
	[self.nextResponder touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	isTouchMoved = TRUE;
	UITouch* touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
//	if(maxScrollY>0)
	{
		float delta = touchPos.y - point.y;
		if(curScrollY<0 && delta<0)
			delta /= 2;
		else if(curScrollY>maxScrollY && delta>0)
			delta /= 2;
		[self scrollTo:curScrollY + delta duration:0.0];
	}
	touchPos = point;

	[self.nextResponder touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (isTouchMoved==FALSE)
		[currentTextField resignFirstResponder];
	if(curScrollY<0)
		[self scrollTo:0 duration:0.3];
	else if(curScrollY>maxScrollY)
		[self scrollTo:maxScrollY duration:0.3];
	[self.nextResponder touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self.nextResponder touchesCancelled:touches withEvent:event];
}

#pragma mark UITextViewDelegate
- (void) textViewDidBeginEditing:(UITextView *)textView
{
	[self textFieldBeginEditing:textView];
}
- (void) textViewDidEndEditing:(UITextView *)textView
{
	[self textFieldEndEditing:textView];
}
@end
