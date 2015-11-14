//
//  IDNRefreshControl.h
//  IDNFramework
//
//  Created by photondragon on 15/5/17.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import <UIKit/UIKit.h>

// 用于显示上拉刷新、下拉显示更多的控件
// 当用户拖动触发刷新的时候，控件会发出ValueChanged事件。
// 控件不会自动进入刷新状态，需要手动设置refreshing=YES
// 设置hidden=YES或enable=NO就不会触发此事件。
@interface IDNRefreshControl : UIControl

@property (nonatomic,weak) UIScrollView* containerView;//当设置这个属性时，刷新控件就会自动加入这个containerView

@property (nonatomic) BOOL refreshing;

@property (nonatomic) float maxPullingDistance; //拉到这个距离就显示“松开加载更多”。默认值80.0，不得小于50.0
@property (nonatomic) float minPullingDistance; //拉到这个距离就显示百分比。默认值30.0，不得小于20
@property (nonatomic) float pulledDistance; //已经拉的距离，通过设置这个属性控制控件的状态。pulledDistance>=maxPullingDistance表示拉到位了。如果设置一个负数，将被改为0
@property (nonatomic,readonly) BOOL isMaxPulling;

@property (nonatomic,copy) NSAttributedString* normalTitle; //正常状态下显示的文本。默认@"下拉显示更多"
@property (nonatomic,copy) NSAttributedString* pullingTitle; //正在拉状态下显示的文本。默认@"下拉显示更多"
@property (nonatomic,copy) NSAttributedString* pulledTitle; //拉到位状态下显示的文本。默认@"松开加载更多"
@property (nonatomic,copy) NSAttributedString* refreshingTitle; //正在刷新状态下显示的文本。默认@"正在加载更多"

- (instancetype)initAtBottom:(BOOL)atBottom; //刷新控件就放在容器的顶部还是底部（下拉刷新还是上拉加载更多）

@end

@interface UITableView(IDNRefreshControl)
@property(nonatomic,strong,readonly) IDNRefreshControl* topRefreshControl;//首次访问此属性时，会在tableView中创建刷新控件，无法移除，只能设置topRefreshControl.hidden = YES将其隐藏。
@property(nonatomic,strong,readonly) IDNRefreshControl* bottomRefreshControl;//首次访问此属性时，会在tableView中创建刷新控件，无法移除，只能设置bottomRefreshControl.hidden = YES将其隐藏。
- (void)refreshRowsModified:(NSArray*)modified deleted:(NSArray*)deleted added:(NSArray*)added inSection:(NSInteger)section;

@end