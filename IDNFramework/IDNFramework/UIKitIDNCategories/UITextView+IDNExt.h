//
//  UITextView+IDNExt.h
//  IDNFramework
//
//  Created by photondragon on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 注意: 当设置了delegate后, 内部会立刻用一个桥接对象取代delegate对象, 所以获取delegate属性得到的对象不是你设置的delegate对象, 但各种通知delegate对象都能正常收到
 文本过滤的实现细节:
 内部使用了一个delegate来桥接外部的delegate.
 文本过滤操作(由acceptCharacterSet, textLimit属性控制)是在文本被改变了(textViewDidChange:)之后进行,
 而不是在textView:shouldChangeTextInRange:replacementText:回调中进行的.
 */
@interface UITextView(IDNExt)

@property(nonatomic,strong) NSCharacterSet* acceptCharacterSet; //可接受的字符集. 为nil则不作任何过滤
@property(nonatomic) NSUInteger textLimit; //文本长度限制. 0表示没限制

@property(nonatomic) BOOL isEditedByUser; // 用户是否输入或删除过文本框中的内容. 可以设置(重置)isEditedByUser = NO, 但不能设置为YES

@property(nonatomic,strong) void (^textChangedByUserBlock)(); //由用户操作(和文本过滤)引起的文本修改的回调
@property(nonatomic,strong) void (^returnPressedBlock)(); //用户按下确定键的回调(此Block是在textView:shouldChangeTextInRange:replacementText:中*异步*调用)

@property(nonatomic,copy,readonly) NSString* selectedText; //当前选中的文本
@property(nonatomic,copy,readonly) NSString* markedText; //当前marked的文本(用户输入的暂时还没有被确认的文本)
@property(nonatomic,copy,readonly) NSString* unmarkedText; //当前文本中未被marked的部分

- (void)clearByUser; //相当于用户按下Clear键. 只在文本框为firstResponder时可用
- (void)deleteBackwardByUser; //相当于用户按下删除键. 只在文本框为firstResponder时可用

@end
