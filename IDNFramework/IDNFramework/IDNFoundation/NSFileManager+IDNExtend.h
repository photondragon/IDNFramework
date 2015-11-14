//
//  NSFileManager+IDNExtend.h
//  Contacts
//
//  Created by photondragon on 15/4/19.
//  Copyright (c) 2015年 no. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager(IDNExtend)

+ (BOOL)removeDocumentFile:(NSString*)filePath; //filePath为相对于Documents目录的相对路径

@end
