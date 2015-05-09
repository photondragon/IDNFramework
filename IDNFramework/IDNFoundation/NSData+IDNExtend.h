//
//  NSData+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/4/11.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData(IDNExtend)

- (BOOL)writeToDocumentFile:(NSString *)file; //将数据保存到Documents目录下，文件名为file（相对路径，可以包含子目录，如果子目录不存在，会自动创建）

@end
