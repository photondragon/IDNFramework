//
//  IDNScanCodeView.h
//  IDNFramework
//
//  Created by photondragon on 15/6/13.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNScanCodeView.h"
#import <AVFoundation/AVFoundation.h>

@interface IDNScanCodeView()
<AVCaptureMetadataOutputObjectsDelegate>
@property(strong,nonatomic) AVCaptureDevice *device;
@property(strong,nonatomic) AVCaptureMetadataOutput *output;
@property(strong,nonatomic) AVCaptureSession *session;
@property(strong,nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic,strong) UILabel* labelNoPrivilege;

@end

@implementation IDNScanCodeView

- (void)initialize
{
	if(_previewLayer==nil && _labelNoPrivilege==nil)
	{
		//device
		self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
		//input
		AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
		if(deviceInput==nil)//没有权限或没有相机
		{
			_labelNoPrivilege = [[UILabel alloc] initWithFrame:self.bounds];
			_labelNoPrivilege.textColor = [UIColor colorWithWhite:0.8 alpha:1];
			_labelNoPrivilege.textAlignment = NSTextAlignmentCenter;
			_labelNoPrivilege.numberOfLines = 0;
			_labelNoPrivilege.font = [UIFont systemFontOfSize:20];
			_labelNoPrivilege.text = @"无权访问相机";
			_labelNoPrivilege.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			[self addSubview:_labelNoPrivilege];
			
			return;
		}
		
		// Output
		self.output = [[AVCaptureMetadataOutput alloc]init];
		[self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
		// 条码类型
		if(self.output.availableMetadataObjectTypes.count>0)
			self.output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
//												AVMetadataObjectTypeQRCode,
												AVMetadataObjectTypeCode93Code,];
		
		// Session
		self.session = [[AVCaptureSession alloc]init];
		[self.session setSessionPreset:AVCaptureSessionPresetPhoto];
		if ([self.session canAddInput:deviceInput])
			[self.session addInput:deviceInput];
		if ([self.session canAddOutput:self.output])
			[self.session addOutput:self.output];
		
		// 预览Layer
		self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
		self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	}
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self initialize];
	}
	return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initialize];
	}
	return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self initialize];
	}
	return self;
}

- (void)didMoveToWindow
{
	if (self.window==nil) {
		[self stopScan];
	}
}

- (void)setInterestRect:(CGRect)interestRect
{
	CGSize framesize = self.frame.size;
	interestRect.origin.x /= framesize.width;
	interestRect.origin.y /= framesize.height;
	interestRect.size.width /= framesize.width;
	interestRect.size.height /= framesize.height;
	_interestRect = interestRect;
	self.output.rectOfInterest = interestRect;
}

- (BOOL)flashLightOn
{
	return self.device.torchMode==AVCaptureTorchModeOn;
}
- (void)setFlashLightOn:(BOOL)flashLightOn
{
	if(_device.hasTorch)
	{
		[_device lockForConfiguration:nil];
		if(flashLightOn)
		{
			[_device setTorchMode:AVCaptureTorchModeOn];
		}
		else
		{
			[_device setTorchMode:AVCaptureTorchModeOff];
		}
		[_device unlockForConfiguration];
	}
}
- (BOOL)scanning
{
	return self.session.running;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	self.previewLayer.frame = self.bounds;
	AVCaptureVideoOrientation orientation;
	UIInterfaceOrientation deviceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	if(deviceOrientation==UIInterfaceOrientationLandscapeLeft)
		orientation = AVCaptureVideoOrientationLandscapeLeft;
	else if(deviceOrientation==UIInterfaceOrientationLandscapeRight)
		orientation = AVCaptureVideoOrientationLandscapeRight;
	else if(deviceOrientation==UIInterfaceOrientationPortrait)
		orientation = AVCaptureVideoOrientationPortrait;
	else// if(deviceOrientation==UIInterfaceOrientationPortraitUpsideDown)
		orientation = AVCaptureVideoOrientationPortraitUpsideDown;
	self.previewLayer.connection.videoOrientation = orientation;
}

- (void)startScan;
{
	[self.layer addSublayer:self.previewLayer];
	[self.session startRunning];
}

- (void)stopScan
{
	[self.session stopRunning];
	[self.previewLayer removeFromSuperlayer];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
	NSMutableArray* strings = [NSMutableArray array];
	for (AVMetadataMachineReadableCodeObject *metadataObject in metadataObjects) {
		[strings addObject:metadataObject.stringValue];
	}
	
	[self stopScan];
	
	if([self.delegate respondsToSelector:@selector(scanCodeView:codeStrings:)])
		[self.delegate scanCodeView:self codeStrings:strings];
}

@end
