//
//  IDNSegList.h
//

#import <Foundation/Foundation.h>

@protocol IDNSegListObserver;

/**
 封装了“分段获取可变列表”算法的类，并且有自动持久化功能。
 子类只要重载两个方法，实现具体数据的提取即可。
 */
@interface IDNSegList : NSObject

@property(nonatomic) NSInteger segmentLength;	//一段的长度

@property(nonatomic,strong,readonly) NSArray* list;
@property(nonatomic,readonly) BOOL reachEnd; //是否取到了列表末尾。这个属性不会影响moreWithFinishedBlock:方法

// reload优先级高于refresh。如果正在 refreshing 时调用reload，则refresh自动变为reload；如果 reloading 时调用 refresh，以reload为准。
- (void)refreshWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //获取列表前一段
- (void)reloadWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //重新加载列表
- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //获取列表后一段
- (void)deleteRecords:(NSArray*)records;
- (void)replaceRecords:(NSArray*)records;
#pragma mark 观察者

// observers未加锁，只能在主线程添加或删除观察者，也不得在观察者通知方法里添加删除观察者。
- (void)addSegListObserver:(id<IDNSegListObserver>)observer; //对observer是weak型弱引用，所以无需手动删除segListObserver。
- (void)delSegListObserver:(id<IDNSegListObserver>)observer;

#pragma mark 子类应该重载的方法（外部不要调用这些方法）

/**
 获取列表尾部一段条目，通过callback返回数据。
 @param record 获取这个条目之后的N条记录。record==nil表示首次调用，此时应该获取列表第一段条目。
 @param callback 子类的实现中，当获取到数据（或失败）时，必须调用callback，传入获取到的条目或者error，否则列表会永远处于loadingTail状态，无法再发出新的more请求。
 */
- (void)queryAfterRecord:(id)record count:(NSInteger)count callback:(void (^)(NSArray* records, BOOL reachEnd, NSError* error))callback;

// 此方法用于refresh操作，如果列表只有reload操作，则无需重载此函数
- (NSComparisonResult)compareRecord:(id)aRecord withRecord:(id)anotherRecord;

// 此方法用于delete和replace操作，如果列表没有这些操作操作，则无需重载此函数
- (BOOL)doesRecord:(id)record hasSameIDWithRecord:(id)anotherRecord; //两条记录的ID是否一样。调用deleteRecords:或replaceRecords:会触发本函数被调用。


#pragma mark 持久化

@property(nonatomic,copy,readonly) NSString* persistFilePath; //持久化文件路径。每当列表内容改变后，会自动保存到这个文件中。不可更改，只能在初始化时设置。
- (instancetype)initWithPersistFilePath:(NSString*)persistFilePath; //persistFilePath可以为nil

/**
 持久化默认只保存list中的数据，要想保存额外的数据，需要在子类的初始化方法中设置和获取这些额外的数据
 
 以下示例是某个子类的init方法
 @code
 - (instancetype)init
 {
	self = [super initWithPersistFilePath:[NSString documentsPathWithFileName:@"string.dat"]];
	if (self) {
		string = [self persistObjectForName:@"string"];
		if(string==nil)
		{
			string = [NSString stringWithString:@"Hello, world!"];
			[self setPersistObject:string forName:@"string"];
		}
	}
	return self;
 }
 @endcode
 
 保存额外数据应该是一个极少要用到的功能，要慎用；
 如果产生了这个需求，首先应该考虑这个需求是否合理，也就是说这个额外数据是否和列表数据是强相关的，
 如果不是强相关的，尽可能把这些额外数据保存在其它地方，而不是和列表数据保存在一起。

 */
- (id)persistObjectForName:(NSString*)name;

/**
 保存需要持久化的数据
 @param object 要持久化的对象。注意这个对象应该是不可变的，或者是在保存了以后就不再改变。
 */
- (void)setPersistObject:(id)object forName:(NSString*)name;

@end

@protocol IDNSegListObserver <NSObject>
@optional
/**
 当SegList列表条目发生变化时，此通知方法会在主线程被调用，可以用于更新TableView的显示。
 三个参数是NSNumber的数组，分别包含删除的条目的位置索引、添加的条目的位置索引和修改的条目的位置索引。
 位置索引的值与操作顺序相关，先修改，再删除（从后向前），最后添加（从前往后）。
 调用-more或-refresh可能会使用列表发生变化，此方法的调用时机是在finishedBlock之前。
 */
- (void)segList:(IDNSegList*)segList modifiedIndics:(NSArray*)modifiedIndics deletedIndics:(NSArray*)deletedIndics addedIndics:(NSArray*)addedIndics;

@end
