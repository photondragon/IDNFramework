//
//  NSObject+IDNModel.h
//  IDNFramework
//
//  Created by photondragon on 16/5/28.
//  Copyright © 2016年 iosdev.net. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IDNModelFieldType) {
	IDNModelFieldTypeNone=0,
	IDNModelFieldTypeString,
	IDNModelFieldTypeInt32,
	IDNModelFieldTypeFloat,
	IDNModelFieldTypeDouble,
	IDNModelFieldTypeBool,
	IDNModelFieldTypeList,
	IDNModelFieldTypeMap,
	IDNModelFieldTypeChars,
};

@interface NSObject(IDNModel)

+ (NSArray*)fieldNames;
+ (NSDictionary*)fieldTypes;

//@property(nonatomic,strong) NSDictionary* rawKeyValues; //原始数据

+ (instancetype)modelWithFieldValues:(NSDictionary*)fieldValues;
- (void)loadFieldValues:(NSDictionary*)fieldValues; //只加载存在的字段，如果某key存在但是其值为NSNull，则视为不存在
- (NSDictionary*)getFieldValues;

@end
