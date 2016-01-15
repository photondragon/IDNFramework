//
//  IDNColorButton.h
//  IDNFramework
//
//  Created by photondragon on 15/6/6.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNColorButton.h"

@interface IDNColorButton()
{
	UIColor* savedBackgroundColor;
}
@end
@implementation IDNColorButton

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	savedBackgroundColor = self.backgroundColor;
	self.backgroundColor = self.tintColor;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	self.backgroundColor = savedBackgroundColor;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	self.backgroundColor = savedBackgroundColor;
}

@end
