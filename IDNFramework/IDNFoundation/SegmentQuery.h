//
//  SegmentQuery.h
//  miku
//
//  Created by fred on 14/11/27.
//  Copyright (c) 2014年 ywiosdev. All rights reserved.
//

#import <Foundation/Foundation.h>

// 本类是线程安全的。
// 分段查询。只追加后段数据，前段数据（已获取数据）不更新
// 比如查询结果总共有10k条数据，如果一次把所有的ID都返回，数据量可能太大；所以一次最多只获取500个ID，如果要获取剩下的ID列表，需要再发送一次查询请求。
// 本类使用了模版方法模式。不要实例化此类。实际中应该继承这个类，重载其-queryAfterRecord:count:方法实现实际的查询操作
@interface SegmentQuery : NSObject

@property(atomic,readonly)BOOL reachEnd;	//是否到达查询结果列表的结尾（获取了所有查询结果）。如果YES，就不需要再调用-more方法了。
@property(atomic,readonly) NSArray* list;	//（已获取的）查询结果列表。
@property(atomic)NSInteger segmentLength;	//一段的长度。每调用一次-more方法，就获取segmentLength条记录。默认值20
@property(nonatomic,strong) void (^listChangedBlock)(NSDictionary*deleted, NSDictionary*added, NSDictionary* modified);//当列表有变化时，此Block会被调用，三个参数是三个字典，分别包含删除的条目、添加的条目和修改的条目。调用-more或-refresh可能会使用列表发生变化。此block只会在主线程中被调用

// 重载点，子类应该重载这个方法，实现实际的查询操作（参考模版方法模式）。
// 当查询失败（比如网络中断）应该返回nil；查询成功应该返回包含查询到的记录的有序数组，查询结果为空应该返回空数组@[]。
// 查询指定记录record之后的count条记录，返回查询到的记录的有序数组。
// record==nil表示首次查询，应该返回总查询结果的前count条记录（第1段）
- (NSArray*)queryAfterRecord:(id)record count:(NSInteger)count error:(NSError**)error;

// 重载点，比较两条记录的大小（排序顺序）。用于refresh方法中比对新增条目，子类必须重载这个方法。aRecord和anotherRecord永远不可能为nil。
- (NSComparisonResult)compareRecord:(id)aRecord withRecord:(id)anotherRecord;

// 重载点，比较两条信息的ID是否一致（同一条记录），并且信息是否被修改过。如果两条信息的ID不一致，说明-compareRecord:withRecord:方法的实现有问题，把不相等的两个元素错当成相等了，这个情况不应该出现，此时抛出异常比较合适。如果检测到newInfo比较oldInfo还要旧，说明数据本身出错了，或者也有可能服务器归档。
- (BOOL)isRecordModifiedWithOldInfo:(id)oldInfo newInfo:(id)newInfo;

- (void)recordChanged:(id)changedRecord; //record可能是新增，也可能是修改
- (void)recordDeleted:(id)deletedRecord; //记录被删除

- (NSError*)more; //获取更多数据。返回查询到的记录条数，查询失败返回-1。可在“上拉显示更多”时调用此方法。
- (NSError*)refresh; //先尝试获取第一段数据，与当前已获取的数据进行比对，找出其中的新增的条目，插入到本地列表中；如果发现新获取的第一段记录中的所有条目都是新增的，说明本地的列表已经很久没有更新了，这个时候就清除之前的所有数据，只保留最新请求第1段。可以在“下拉刷新”时调用本方法
- (NSError*)reload; //重新加载（先清除之前的查询结果，再加载第一段）
@end
