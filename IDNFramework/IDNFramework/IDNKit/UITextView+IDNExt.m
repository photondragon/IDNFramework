//
//  UITextView+IDNExt.m
//  IDNFramework
//
//  Created by photondragon on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "UITextView+IDNExt.h"
#import <objc/runtime.h>
#import "NSString+IDNExtend.h"
#import "NSObject+IDNCustomObject.h"
#import "NSObject+IDNPerformSelector.h"

@interface UITextViewIDNExtDelegateAdaptor : NSObject
<UITextViewDelegate>

@property(nonatomic,weak) UITextView* textView;
@property(nonatomic,weak) id<UITextViewDelegate> outDelegate;

@end

#pragma mark -

@implementation UITextView(IDNExt)

//- (void)dealloc
//{
////	[self unsetDelegateAdaptor];
////	self.delegate = nil;
////	NSLog(@"%s", __func__);
//}

#pragma mark - Delegate adaptor

- (void)setDelegateAdaptor
{
	UITextViewIDNExtDelegateAdaptor* delegateAdaptor = [self customObjectForKey:@"idn_delegateAdaptor"];
	if(delegateAdaptor==nil) //没有adaptor
	{
		delegateAdaptor = [UITextViewIDNExtDelegateAdaptor new];
		delegateAdaptor.textView = self;
//		[self addObserver:delegateAdaptor forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew context:nil];
//		NSLog(@"addObserver delegate");
		[self setCustomObject:delegateAdaptor forKey:@"idn_delegateAdaptor"];
	}
//	id<UITextViewDelegate> delegate = self.delegate;
//	if(delegate!=delegateAdaptor)
//		delegateAdaptor.outDelegate = delegate;
	self.delegate = delegateAdaptor;
}

- (void)unsetDelegateAdaptor
{
	UITextViewIDNExtDelegateAdaptor* delegateAdaptor = [self customObjectForKey:@"idn_delegateAdaptor"];
	if(delegateAdaptor==nil) //没有adaptor
		return;
//	id<UITextViewDelegate> delegate = delegateAdaptor.outDelegate;
//	[self removeObserver:delegateAdaptor forKeyPath:@"delegate"];
//	NSLog(@"removeObserver delegate");
	[self setCustomObject:nil forKey:@"idn_delegateAdaptor"];
//	self.delegate = delegate;
	self.delegate = nil;
}

- (void)updateDelegateAdaptor
{
	if(self.textLimit>0 || self.acceptCharacterSet)
		[self setDelegateAdaptor];
	else
		[self unsetDelegateAdaptor];
}

- (void)outDelegateChanged
{
	UITextViewIDNExtDelegateAdaptor* delegateAdaptor = [self customObjectForKey:@"idn_delegateAdaptor"];
	if(delegateAdaptor==nil)
		return;
	delegateAdaptor.outDelegate = self.delegate;
	self.delegate = delegateAdaptor;
}

#pragma mark - 过滤

- (NSUInteger)textLimit
{
	return [[self customObjectForKey:@"IDNExt_textLimit"] unsignedIntegerValue];
}
- (void)setTextLimit:(NSUInteger)textLimit
{
	[self setCustomObject:@(textLimit) forKey:@"IDNExt_textLimit"];
	[self updateDelegateAdaptor];
}

- (NSCharacterSet*)acceptCharacterSet
{
	return [self customObjectForKey:@"IDNExt_acceptCharacterSet"];
}
- (void)setAcceptCharacterSet:(NSCharacterSet *)acceptCharacterSet
{
	[self setCustomObject:acceptCharacterSet forKey:@"IDNExt_acceptCharacterSet"];
	[self updateDelegateAdaptor];
}

// 过滤(这里是动词)
- (void)filterTextWithNotifyChanged:(BOOL)notifyChanged
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
		
		if(notifyChanged)
			[self.delegate textViewDidChange:self]; //通知文本修改
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

@implementation UITextViewIDNExtDelegateAdaptor

- (void)dealloc
{
	NSLog(@"%s", __func__);
	[_textView unsetDelegateAdaptor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
	id<UITextViewDelegate> delegate = [change objectForKey:NSKeyValueChangeNewKey];
	if([delegate isKindOfClass:[UITextViewIDNExtDelegateAdaptor class]]==NO) // 不是Adaptor
		[_textView outDelegateChanged];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	return _outDelegate;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if(aSelector==@selector(textViewDidChange:) ||
	   aSelector==@selector(textView:shouldChangeTextInRange:replacementText:) ||
	   aSelector==@selector(textViewDidEndEditing:))
		return YES;
	else if(aSelector==@selector(textViewShouldBeginEditing:) ||
			aSelector==@selector(textViewShouldEndEditing:) ||
			aSelector==@selector(textViewDidBeginEditing:) ||
			aSelector==@selector(textViewDidChangeSelection:) ||
			aSelector==@selector(textView:shouldInteractWithTextAttachment:inRange:) ||
			aSelector==@selector(textView:shouldInteractWithURL:inRange:) ||
			aSelector==@selector(scrollViewDidScroll:) ||
			aSelector==@selector(scrollViewDidZoom:) ||
			aSelector==@selector(scrollViewWillBeginDragging:) ||
			aSelector==@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:) ||
			aSelector==@selector(scrollViewDidEndDragging:willDecelerate:) ||
			aSelector==@selector(scrollViewWillBeginDecelerating:) ||
			aSelector==@selector(scrollViewDidEndDecelerating:) ||
			aSelector==@selector(scrollViewDidEndScrollingAnimation:) ||
			aSelector==@selector(viewForZoomingInScrollView:) ||
			aSelector==@selector(scrollViewWillBeginZooming:withView:) ||
			aSelector==@selector(scrollViewDidEndZooming:withView:atScale:) ||
			aSelector==@selector(scrollViewShouldScrollToTop:) ||
			aSelector==@selector(scrollViewDidScrollToTop:)
			)
		return [_outDelegate respondsToSelector:aSelector];
	
	return [super respondsToSelector:aSelector];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	// 立刻过滤, 因为取消焦点后, 之前的marked文本可能包含非法字符, 需要过滤
	[textView filterTextWithNotifyChanged:YES];
	
	if([_outDelegate respondsToSelector:@selector(textViewDidEndEditing:)])
		[_outDelegate textViewDidEndEditing:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if([text isEqualToString:@"\n"])
	{
		void (^returnPressedBlock)() = textView.returnPressedBlock;
		if(returnPressedBlock)
			dispatch_async(dispatch_get_main_queue(), returnPressedBlock);
	}
	if([_outDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)])
		return [_outDelegate textView:textView shouldChangeTextInRange:range replacementText:text];
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
	[textView setIsEditedByUserYES];
	
	[textView filterTextWithNotifyChanged:NO];
	
	if([_outDelegate respondsToSelector:@selector(textViewDidChange:)])
		[_outDelegate textViewDidChange:textView];
	
	void (^textChangedByUserBlock)() = textView.textChangedByUserBlock;
	if(textChangedByUserBlock)
		textChangedByUserBlock();
}

@end
