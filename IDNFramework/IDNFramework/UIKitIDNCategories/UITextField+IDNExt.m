//
//  UITextField+IDNExt.m
//  IDNFramework
//
//  Created by photondragon on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UITextField+IDNExt.h"
#import <objc/runtime.h>
#import "NSString+IDNExtend.h"
#import "NSObject+IDNCustomObject.h"
#import "NSObject+IDNPerformSelector.h"

@interface UITextFieldIDNDel2ClearDelegator : NSObject
<UITextFieldDelegate>

@property(nonatomic,assign) id<UITextFieldDelegate> outDelegate;

- (void)textEditingBegin:(UITextField*)textField;
- (void)textEditingEnd:(UITextField*)textField;
- (void)textEditingChanged:(UITextField*)textField;

@end

#pragma mark -

@implementation UITextField(IDNExt)

#pragma mark - delegate adaptor

+ (void)initialize
{
	static BOOL replaced = NO;
	if(replaced==NO)
	{
		replaced = YES;
		Method oldMethod = class_getInstanceMethod([UITextField class], @selector(setDelegate:));
		Method newMethod = class_getInstanceMethod([UITextField class], @selector(setIDNDel2ClearDelegate:));
		method_exchangeImplementations(oldMethod, newMethod);
		
		Method oldGetDelegateMethod = class_getInstanceMethod([UITextField class], @selector(delegate));
		Method newGetDelegateMethod = class_getInstanceMethod([UITextField class], @selector(getIDNDel2ClearDelegate));
		method_exchangeImplementations(oldGetDelegateMethod, newGetDelegateMethod);
	}
}

- (id<UITextFieldDelegate>)getIDNDel2ClearDelegate
{
	UITextFieldIDNDel2ClearDelegator* innerDelegator = [self idn_innerDelegator];
	if(innerDelegator)
		return innerDelegator.outDelegate;
	return [self getIDNDel2ClearDelegate];
}
- (void)setIDNDel2ClearDelegate:(id<UITextFieldDelegate>)delegate
{
	UITextFieldIDNDel2ClearDelegator* innerDelegator = [self idn_innerDelegator];
	if(innerDelegator)
	{
		innerDelegator.outDelegate = delegate;
	}
	else
		[self setIDNDel2ClearDelegate:delegate];
}

#pragma mark - Inner Delegate

- (UITextFieldIDNDel2ClearDelegator*)idn_innerDelegator
{
	return [self customObjectForKey:@"idn_innerDelegator"];
}
- (void)setIdn_innerDelegator:(UITextFieldIDNDel2ClearDelegator*)innerDelegator
{
	UITextFieldIDNDel2ClearDelegator* oldInnerDelegator = [self idn_innerDelegator];
	if(oldInnerDelegator)
	{
		[self setIDNDel2ClearDelegate:oldInnerDelegator.outDelegate];
		[self removeTarget:oldInnerDelegator action:@selector(textEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
		[self removeTarget:oldInnerDelegator action:@selector(textEditingEnd:) forControlEvents:UIControlEventEditingDidEnd];
		[self removeTarget:oldInnerDelegator action:@selector(textEditingChanged:) forControlEvents:UIControlEventEditingChanged];
	}
	
	[self setCustomObject:innerDelegator forKey:@"idn_innerDelegator"];
	
	if(innerDelegator)
	{
		innerDelegator.outDelegate = [self getIDNDel2ClearDelegate];
		[self setIDNDel2ClearDelegate:innerDelegator];
		[self addTarget:innerDelegator action:@selector(textEditingBegin:) forControlEvents:UIControlEventEditingDidBegin];
		[self addTarget:innerDelegator action:@selector(textEditingEnd:) forControlEvents:UIControlEventEditingDidEnd];
		[self addTarget:innerDelegator action:@selector(textEditingChanged:) forControlEvents:UIControlEventEditingChanged];
	}
}

- (void)updateInnerDelegater
{
	if(self.shouldClearWhenFirstDelete || self.textLimit>0 || self.acceptCharacterSet)
		[self setIdn_innerDelegator:[UITextFieldIDNDel2ClearDelegator new]];
	else
		[self setIdn_innerDelegator:nil];
}

#pragma mark - clearWhenFirstDelete

- (BOOL)shouldClearWhenFirstDelete
{
	return [[self customObjectForKey:@"IDNExt_shouldClearWhenFirstDelete"] boolValue];
}
- (void)setShouldClearWhenFirstDelete:(BOOL)shouldClearWhenFirstDelete
{
	[self setCustomObject:@(shouldClearWhenFirstDelete) forKey:@"IDNExt_shouldClearWhenFirstDelete"];
	[self updateInnerDelegater];
}

#pragma mark - 过滤

- (NSUInteger)textLimit
{
	return [[self customObjectForKey:@"IDNExt_textLimit"] unsignedIntegerValue];
}
- (void)setTextLimit:(NSUInteger)textLimit
{
	[self setCustomObject:@(textLimit) forKey:@"IDNExt_textLimit"];
	[self updateInnerDelegater];
}

- (NSCharacterSet*)acceptCharacterSet
{
	return [self customObjectForKey:@"IDNExt_acceptCharacterSet"];
}
- (void)setAcceptCharacterSet:(NSCharacterSet *)acceptCharacterSet
{
	[self setCustomObject:acceptCharacterSet forKey:@"IDNExt_acceptCharacterSet"];
	[self updateInnerDelegater];
}

- (void)IDNExt_setNeedsFilter:(BOOL)needsFilter
{
	if(needsFilter==[[self customObjectForKey:@"IDNExt_needsFilter"] boolValue])
		return;
	[self setCustomObject:@(needsFilter) forKey:@"IDNExt_needsFilter"];
	
	[NSObject cancelPreviousPerformRequestsWithTargetWeakly:self selector:@selector(IDNExt_filter) object:nil];
	if(needsFilter)
		[self performSelectorWeakly:@selector(IDNExt_filter) withObject:nil afterDelay:0];
}

// 过滤(这里是动词)
- (void)IDNExt_filter
{
	BOOL filtered = NO;
	NSString* text = nil;
	
	NSInteger cursorMoveOffset = 0;
	NSInteger cursorOffset = 0;
	
	NSCharacterSet* charSet = self.acceptCharacterSet;
	if(charSet)
	{
		NSString* t1 = [self textBeforeCursor];
		NSString* t12 = [t1 stringByRemovingCharactersInSet:charSet.invertedSet];
		if(t1.length != t12.length) //前段被过滤
		{
			cursorMoveOffset = t12.length - t1.length;
			t1 = t12;
			filtered = YES;
		}
		NSString* t2 = [self textAfterCursor];
		NSString* t22 = [t2 stringByRemovingCharactersInSet:charSet.invertedSet];
		if(t2.length != t22.length) //被过滤了
		{
			t2 = t22;
			filtered = YES;
		}
		if(t1.length && t2.length)
			text = [NSString stringWithFormat:@"%@%@", t1, t2];
		else if(t1.length)
			text = t1;
		else if(t2.length)
			text = t2;
		else
			text = @"";
		cursorOffset = t1.length;
	}
	
	NSInteger limit = self.textLimit;
	if(limit>0)
	{
		if(text==nil)
			text = self.unmarkedText;
		if(text.length>limit)
		{
			text = [text truncateWithLength:limit];
			filtered = YES;
			
			if(limit<cursorOffset) //如果没有charSet过滤, cursorOffset==0
			{
				cursorMoveOffset -= cursorOffset - limit;
			}
		}
	}
	
	[self IDNExt_setNeedsFilter:NO];
	
	if(filtered)
	{
		UITextRange* selRange = self.selectedTextRange;
		if(selRange)
		{
			UITextPosition* pos = [self positionFromPosition:selRange.start offset:cursorMoveOffset];
			self.text = text;
			self.selectedTextRange = [self textRangeFromPosition:pos toPosition:pos];
		}
		else
			self.text = text;
		[self sendActionsForControlEvents:UIControlEventEditingChanged];
	}
}

#pragma mark - 其它

- (void)clearByUser
{
	if(self.selectedTextRange==nil)
		return;
	UITextRange* removeRange = [self textRangeFromPosition:[self beginningOfDocument] toPosition:[self endOfDocument]];
	self.selectedTextRange = removeRange;
	[self deleteBackward];
}

- (void)deleteBackwardByUser
{
	UITextRange* selectedRange = [self selectedTextRange];
	if(selectedRange==nil)
		return;
	if(selectedRange.empty)//当前没有文本被选中
	{
		UITextPosition* removeStart = [self positionFromPosition:selectedRange.start offset:-1];
		UITextRange* removeRange = [self textRangeFromPosition:removeStart toPosition:selectedRange.end];
		self.selectedTextRange = removeRange;
	}
	
	[self deleteBackward];
}

- (NSString*)selectedText
{
	return [self textInRange:[self selectedTextRange]];
}

- (NSString*)markedText
{
	return [self textInRange:[self markedTextRange]];
}

- (NSString*)unmarkedText
{
	UITextRange* selRange = [self markedTextRange];
	if(selRange==nil || selRange.empty)
		return self.text;
	UITextRange* range1 = [self textRangeFromPosition:[self beginningOfDocument] toPosition:selRange.start];
	UITextRange* range2 = [self textRangeFromPosition:selRange.end toPosition:[self endOfDocument]];
	NSMutableString* as = [NSMutableString new];
	if(range1.empty==NO)
		[as appendString:[self textInRange:range1]];
	if(range2.empty==NO)
		[as appendString:[self textInRange:range2]];
	return [as copy];
}

- (NSString*)textBeforeCursor //光标之前的文本
{
	UITextRange* selRange = [self markedTextRange];
	if(selRange==nil)
	{
		selRange = [self selectedTextRange];
		if(selRange==nil)
			return self.text;
	}
	UITextRange* range1 = [self textRangeFromPosition:[self beginningOfDocument] toPosition:selRange.start];
	return [self textInRange:range1];
}
- (NSString*)textAfterCursor //光标之后的文本
{
	UITextRange* selRange = [self markedTextRange];
	{
		selRange = [self selectedTextRange];
		if(selRange==nil)
			return nil;
		else if(selRange.empty==NO)
			selRange = [self textRangeFromPosition:selRange.start toPosition:selRange.start];
	}
	UITextRange* range2 = [self textRangeFromPosition:selRange.end toPosition:[self endOfDocument]];
	return [self textInRange:range2];
}

- (BOOL)isEditedByUser
{
	return [[self customObjectForKey:@"idn_isEditedByUser"] boolValue];
}
- (void)setIsEditedByUser:(BOOL)isEditedByUser
{
	if(isEditedByUser==YES)
		return;
	[self setCustomObject:@NO forKey:@"idn_isEditedByUser"];
}
- (void)setIsEditedByUserYES
{
	[self setCustomObject:@YES forKey:@"idn_isEditedByUser"];
}

- (void (^)())returnPressedBlock
{
	return [self customObjectForKey:@"idn_returnPressedBlock"];
}
- (void)setReturnPressedBlock:(void (^)())returnPressedBlock
{
	[self setCustomObject:returnPressedBlock forKey:@"idn_returnPressedBlock"];
}

- (void (^)())textChangedByUserBlock
{
	return [self customObjectForKey:@"idn_textChangedByUserBlock"];
}
- (void)setTextChangedByUserBlock:(void (^)())textChangedByUserBlock
{
	[self setCustomObject:textChangedByUserBlock forKey:@"idn_textChangedByUserBlock"];
}

@end

#pragma mark -

@implementation UITextFieldIDNDel2ClearDelegator

- (void)textEditingBegin:(UITextField*)textField
{
	[textField setCustomObject:@YES forKey:@"willClear"];
}
- (void)textEditingEnd:(UITextField*)textField
{
	[textField setCustomObject:@NO forKey:@"willClear"];
	
	// 立刻过滤, 因为取消焦点后, 之前的marked文本可能包含非法字符, 需要过滤
//	[NSObject cancelPreviousPerformRequestsWithTargetWeakly:textField selector:@selector(IDNExt_filter) object:nil];
	[textField IDNExt_filter];
}
- (void)textEditingChanged:(UITextField*)textField
{
	[textField setIsEditedByUserYES];
	
//	[NSObject cancelPreviousPerformRequestsWithTargetWeakly:textField selector:@selector(IDNExt_filter) object:nil];
	[textField IDNExt_filter];
	
	void (^textChangedByUserBlock)() = textField.textChangedByUserBlock;
	if(textChangedByUserBlock)
		dispatch_async(dispatch_get_main_queue(), textChangedByUserBlock);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if([[textField customObjectForKey:@"willClear"] boolValue])
	{
		[textField setCustomObject:@NO forKey:@"willClear"];
		if(textField.shouldClearWhenFirstDelete && string.length==0)//删除操作
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				textField.text = nil;
				[textField sendActionsForControlEvents:UIControlEventEditingChanged];
			});
			return NO;
		}
	}
	
	if([_outDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
		return [_outDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	void (^returnPressedBlock)() = textField.returnPressedBlock;
	if(returnPressedBlock)
		dispatch_async(dispatch_get_main_queue(), returnPressedBlock);
	
	if([_outDelegate respondsToSelector:@selector(textFieldShouldReturn:)])
	{
		return [_outDelegate textFieldShouldReturn:textField];
	}
	return NO; //当delegate没有实现textFieldShouldReturn:时, 默认要返回NO, 否则键盘会收起
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if(aSelector==@selector(textField:shouldChangeCharactersInRange:replacementString:) ||
	   aSelector==@selector(textFieldShouldReturn:))
		return YES;
	else if(aSelector==@selector(textFieldShouldBeginEditing:) ||
			aSelector==@selector(textFieldDidBeginEditing:) ||
			aSelector==@selector(textFieldShouldEndEditing:) ||
			aSelector==@selector(textFieldDidEndEditing:) ||
			aSelector==@selector(textFieldShouldClear:)
			)
		return [_outDelegate respondsToSelector:aSelector];
	
	return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _outDelegate;
}

@end
