//
//  UIPickerView+IDNPickDate.h
//  IDNFramework
//
//  Created by photondragon on 15/6/23.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPickerView(IDNPickDate)

/**
 在[[UIApplication sharedApplication].delegate window]里显示UIPickerView，内部只是
 简单调用了UIView(IDNPickDate)的功能
 @code
 [UIPickerView pickDateWithChoosedBlock:^(NSDate *date) {
     NSLog(@"选择的时间为：%@", date);
  } mode:UIDatePickerModeDate currentDate:nil minDate:nil maxDate:[NSDate date]];
 @endcode
 */
+ (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock;
+ (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock mode:(UIDatePickerMode)mode currentDate:(NSDate*)currentDate minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate;

@end

@interface UIView(IDNPickDate)
/**
 在指定view里显示一个UIPickerView，用户可以选择一个时间，点确定按钮，然后dateChoosedBlock
 会被调用，参数就是用户选择的时间。
 如果用户取消了选择，dateChoosedBlock不会被调用
 @code
 [self.navigationController.view pickDateWithChoosedBlock:^(NSDate *date) {
     NSLog(@"选择的时间为：%@", date);
  } mode:UIDatePickerModeDate currentDate:nil minDate:nil maxDate:[NSDate date]];
 @endcode
 */
- (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock;
- (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock mode:(UIDatePickerMode)mode currentDate:(NSDate*)currentDate minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate;

@end

