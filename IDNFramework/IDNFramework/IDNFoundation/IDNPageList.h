//
//  IDNPageList.h
//

#import <Foundation/Foundation.h>

@protocol IDNPageListObserver;

/**
 分页提取，并且有自动持久化功能。
 子类只要重载一个方法，实现具体数据的提取即可。
 不去除重复条目
 */
@interface IDNPageList : NSObject

@property(nonatomic) NSInteger pagesCount; // 当前提了多少页
@property(nonatomic) NSInteger pageSize; // 每页多少条

@property(nonatomic,readonly) BOOL loading; // 是否正在加载

@property(nonatomic,strong,readonly) NSArray* list;
@property(nonatomic,readonly) BOOL reachEnd; //是否取到了列表末尾。这个属性不会影响moreWithFinishedBlock:方法

- (void)reloadWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //重新加载列表
- (void)moreWithFinishedBlock:(void (^)(NSError* error))finishedBlock; //获取列表后一段

- (void)deleteRecordAtIndex:(NSInteger)index;
- (void)replaceRecord:(id)record atIndex:(NSInteger)index;

#pragma mark 观察者

// observers未加锁，只能在主线程添加或删除观察者，也不得在观察者通知方法里添加删除观察者。
- (void)addPageListObserver:(id<IDNPageListObserver>)observer; //对observer是weak型弱引用，所以无需手动删除pageListObserver。
- (void)delPageListObserver:(id<IDNPageListObserver>)observer;

#pragma mark 子类应该重载的方法（外部不要调用这些方法）

/**
 获取一页数据。
 @param pageIndex 要提取的页码, 从0开始。
 @param callback 子类的实现中，当获取到数据（或失败）时，必须调用callback，传入获取到的条目或者error，否则列表会永远处于loading状态，无法再发出新的请求。
 */
- (void)queryWithPageIndex:(NSInteger)pageIndex pageSize:(NSInteger)pageSize callback:(void (^)(NSArray* records, BOOL reachEnd, NSError* error))callback;

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

@protocol IDNPageListObserver <NSObject>
@optional
/**
 当PageList列表条目发生变化时，此通知方法会在主线程被调用，可以用于更新TableView的显示。
 三个参数是NSNumber的数组，分别包含删除的条目的位置索引、添加的条目的位置索引和修改的条目的位置索引。
 位置索引的值与操作顺序相关，先修改，再删除（从后向前），最后添加（从前往后）。
 调用-more或-refresh可能会使用列表发生变化，此方法的调用时机是在finishedBlock之前。
 */
- (void)pageList:(IDNPageList*)pageList modifiedIndics:(NSArray*)modifiedIndics deletedIndics:(NSArray*)deletedIndics addedIndics:(NSArray*)addedIndics;

@end
