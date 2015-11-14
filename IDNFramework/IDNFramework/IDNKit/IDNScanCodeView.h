//
//  IDNScanCodeView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IDNScanCodeViewDelegate;

//条码扫描View，支持条形码EAN-13和QR二维码两种
@interface IDNScanCodeView : UIView

@property(nonatomic,readonly) BOOL scanning;
@property(nonatomic,weak) id<IDNScanCodeViewDelegate> delegate;
@property(nonatomic) CGRect interestRect;//识别区域，以点为单位。
@property(nonatomic) BOOL flashLightOn;

- (void)startScan;
- (void)stopScan;

@end

@protocol IDNScanCodeViewDelegate <NSObject>
@optional
- (void)scanCodeView:(IDNScanCodeView*)scanCodeView codeStrings:(NSArray*)codeStrings;
@end