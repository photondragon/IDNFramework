//
//  UIPickerView+IDNPickDate.h
//  IDNFramework
//
//  Created by photondragon on 15/6/23.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "UIPickerView+IDNPickDate.h"
#import <objc/runtime.h>

@interface IDNPickDateView : UIView

@property (nonatomic,strong) void (^callbackChooseDate)(NSDate* date);
@property (nonatomic) UIDatePickerMode datePickerMode;
@property (nonatomic,strong) NSDate *minimumDate;
@property (nonatomic,strong) NSDate *maximumDate;
@property (nonatomic,strong) NSDate *date;

@end

@implementation IDNPickDateView
{
	UIView* pickView;
	UIDatePicker* datePicker;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initializer];
	}
	return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initializer];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initializer];
	}
	return self;
}

- (void)initializer
{
    if (datePicker)
		return;
	
	CGSize framesize = self.frame.size;
	
	self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
	[self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blankClicked:)]];
	
	float pickRegionHeight = 1+216+8+50;
	
	pickView = [[UIView alloc]initWithFrame:CGRectMake(0, round((framesize.height-pickRegionHeight)/2.0), framesize.width, pickRegionHeight)];
	pickView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[self addSubview:pickView];
	
	//上部横线
	UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, framesize.width, 1)];
	lineView.backgroundColor = [UIColor grayColor];
	lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[pickView addSubview:lineView];

	datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 1, framesize.width, 216)];
	datePicker.backgroundColor = [UIColor whiteColor];
	datePicker.datePickerMode = UIDatePickerModeDateAndTime;
	datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	[pickView addSubview:datePicker];
	
	UIButton *sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[sureBtn setTitle:@"确认" forState:UIControlStateNormal];
	[sureBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
	sureBtn.backgroundColor = [UIColor whiteColor];
	sureBtn.frame = CGRectMake(0, pickRegionHeight-50, framesize.width, 50);
	[sureBtn setTitleColor:[UIColor colorWithRed:27/255.0 green:159/255.0 blue:224/255.0 alpha:1.0] forState:UIControlStateNormal];
	[sureBtn addTarget:self action:@selector(btnOKClick:) forControlEvents:UIControlEventTouchUpInside];
	sureBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[pickView addSubview:sureBtn];
}

- (void)btnOKClick:(id)sender
{
    if(self.callbackChooseDate)
		self.callbackChooseDate(datePicker.date);
}

//隐藏
- (void)blankClicked:(id)sender
{
	if(self.callbackChooseDate)
		self.callbackChooseDate(nil);
}

#pragma mark - get set
- (void)setDatePickerMode:(UIDatePickerMode)mode
{
    datePicker.datePickerMode = mode;
}

- (UIDatePickerMode)datePickerMode
{
    return datePicker.datePickerMode;
}

- (void)setMinimumDate:(NSDate *)aDate
{
    datePicker.minimumDate = aDate;
}
- (NSDate*)minimumDate
{
    return datePicker.minimumDate;
}
- (void)setMaximumDate:(NSDate *)maximumDate
{
	datePicker.maximumDate = maximumDate;
}
- (NSDate*)maximumDate
{
	return datePicker.maximumDate;
}

- (NSDate*)date
{
    return datePicker.date;
}

- (void)setDate:(NSDate *)aDate
{
	if(aDate)
		datePicker.date = aDate;
}

@end

@implementation UIView(IDNPickDate)

static char bindDataKey = 0;

- (NSMutableDictionary*)dictionaryOfUIViewMKPickDateBindData
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic==nil)
	{
		dic = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, &bindDataKey, dic, OBJC_ASSOCIATION_RETAIN);
	}
	return dic;
}

- (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock
{
	[self pickDateWithChoosedBlock:dateChoosedBlock mode:UIDatePickerModeDateAndTime currentDate:nil minDate:nil maxDate:nil];
}

- (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock mode:(UIDatePickerMode)mode currentDate:(NSDate*)currentDate minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate
{
	[self stopPickDate];
	
	NSMutableDictionary* dic = [self dictionaryOfUIViewMKPickDateBindData];

	IDNPickDateView* picker = [[IDNPickDateView alloc] initWithFrame:self.bounds];
	__weak UIView* wself = self;
	picker.callbackChooseDate = ^(NSDate*date){
		UIView* sself = wself;
		
		if(date && dateChoosedBlock)
			dateChoosedBlock(date);
		[sself stopPickDate];
	};
	picker.datePickerMode = mode;
	picker.minimumDate = minDate;
	picker.maximumDate = maxDate;
	picker.date = currentDate;
	picker.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
	[self addSubview:picker];
	dic[@"picker"] = picker;
}

- (void)stopPickDate
{
	NSMutableDictionary* dic = objc_getAssociatedObject(self, &bindDataKey);
	if(dic)
	{
		IDNPickDateView* picker = dic[@"picker"];
		[picker removeFromSuperview];
		[dic removeObjectForKey:@"picker"];
		objc_setAssociatedObject(self, &bindDataKey, nil, OBJC_ASSOCIATION_RETAIN);
	}
}

@end


@implementation UIPickerView(IDNPickDate)

+ (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock
{
	[self pickDateWithChoosedBlock:dateChoosedBlock mode:UIDatePickerModeDateAndTime currentDate:nil minDate:nil maxDate:nil];
}
+ (void)pickDateWithChoosedBlock:(void (^)(NSDate* date))dateChoosedBlock mode:(UIDatePickerMode)mode currentDate:(NSDate*)currentDate minDate:(NSDate*)minDate maxDate:(NSDate*)maxDate
{
	[[[UIApplication sharedApplication].delegate window] pickDateWithChoosedBlock:dateChoosedBlock mode:mode currentDate:currentDate minDate:minDate maxDate:maxDate];
}

@end