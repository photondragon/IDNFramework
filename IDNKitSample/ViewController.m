//
//  ViewController.m
//  IDNKitSample
//
//  Created by mahj on 15/12/2.
//  Copyright © 2015年 iosdev.net. All rights reserved.
//

#import "ViewController.h"
#import "UIButton+IDNColor.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btnTestDisable;
@property (weak, nonatomic) IBOutlet UIButton *btnTestHighlight;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_btnTestDisable.backgroundColorDisabled = [UIColor lightGrayColor];
	_btnTestDisable.enabled = NO;

	_btnTestHighlight.backgroundColorHighlighted = [UIColor redColor];
}

@end
