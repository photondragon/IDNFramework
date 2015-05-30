//
//  IDNSearchBar.m
//  IDNFramework
//
//  Created by photondragon on 15/5/30.
//  Copyright (c) 2015年 iosdev.net. All rights reserved.
//

#import "IDNSearchBar.h"

@interface IDNSearchBar()
<UISearchBarDelegate>

@property(nonatomic,assign) id<UISearchBarDelegate> outDelegate;
@property(nonatomic,strong) UIButton *searchingMaskView;//搜索时显示的MaskView，点击一下就收回键盘
@property(nonatomic,strong) UIButton *searchingStatusBarMaskView;

@end

@implementation IDNSearchBar
{
	UIViewController* autoHideNavBarOfController;
}

- (void)initialize
{
	if(self.delegate==nil)
	{
		self.backgroundImage = [[UIImage alloc] init];
		self.backgroundColor = [UIColor colorWithWhite:220/255.0 alpha:1.0];//如果只修改barTintColor，搜索条上会出现两条黑线，必须加上上面那行代码。
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.enablesReturnKeyAutomatically = NO;
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
		self.spellCheckingType = UITextSpellCheckingTypeNo;
		self.returnKeyType = UIReturnKeySearch;
		[super setDelegate:self];
		
		self.placeholder = @"搜索";
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
- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
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

- (void)setDelegate:(id<UISearchBarDelegate>)delegate
{
	self.outDelegate = delegate;
}
- (id<UISearchBarDelegate>)delegate
{
	return self.outDelegate;
}

- (void)autoHideNavBarOfController:(UIViewController*)controller
{
	if(autoHideNavBarOfController==controller)
		return;
	autoHideNavBarOfController = controller;
}

- (UIButton*)searchingMaskView
{
	if(_searchingMaskView==nil)
	{
		_searchingMaskView = [UIButton buttonWithType:UIButtonTypeCustom];
		_searchingMaskView.hidden = YES;
		_searchingMaskView.backgroundColor = [UIColor colorWithWhite:246/255.0 alpha:0.95];//[UIColor clearColor];//
		_searchingMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_searchingMaskView addTarget:self action:@selector(blankClickedWhenSearching:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _searchingMaskView;
}
- (UIButton*)searchingStatusBarMaskView
{
	if(_searchingStatusBarMaskView==nil)
	{
		_searchingStatusBarMaskView = [UIButton buttonWithType:UIButtonTypeCustom];
		_searchingStatusBarMaskView.hidden = YES;
		_searchingStatusBarMaskView.backgroundColor = [UIColor colorWithWhite:246/255.0 alpha:0.95]; //[UIColor clearColor];//
		_searchingStatusBarMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_searchingStatusBarMaskView addTarget:self action:@selector(blankClickedWhenSearching:) forControlEvents:UIControlEventTouchUpInside];
	}
	return _searchingStatusBarMaskView;
}
- (void)setContainerView:(UIScrollView *)containerView
{
	if(_containerView==containerView)
		return;
	if(_containerView)//从之前的ScrollView中移除
	{
		[self.searchingMaskView removeFromSuperview];
		[self.searchingStatusBarMaskView removeFromSuperview];
		
		if([_containerView isKindOfClass:[UITableView class]])
		{
			UITableView* tableView = (UITableView*)_containerView;
			tableView.tableHeaderView = nil;
		}
		else{
//			UIEdgeInsets inset = _containerView.contentInset;
//			inset.top -= 44;
//			_containerView.contentInset = inset;
			[_containerView.panGestureRecognizer removeTarget:self action:@selector(panGestureRecognizerStateUpdate:)];
			[self removeFromSuperview];
		}
	}
	_containerView = containerView;
	if(containerView)
	{
		CGSize containerSize = containerView.frame.size;
		
		if([_containerView isKindOfClass:[UITableView class]])//加入了table view
		{
			self.frame = CGRectMake(0, 0, containerSize.width, 44);
			UITableView* tableView = (UITableView*)_containerView;
			tableView.tableHeaderView = self;
			
			self.searchingMaskView.frame = CGRectMake(0, -20+64, containerSize.width, containerSize.height+20-64);
			self.searchingStatusBarMaskView.frame = CGRectMake(0, -20, containerSize.width, 20);
		}
		else //加入了普通的scroll view
		{
			self.frame = CGRectMake(0, -44, containerSize.width, 44);
			[containerView addSubview:self];
			[containerView.panGestureRecognizer addTarget:self action:@selector(panGestureRecognizerStateUpdate:)];
			
			self.searchingMaskView.frame = CGRectMake(0, 0+64, containerSize.width, containerSize.height-64);
			self.searchingStatusBarMaskView.frame = CGRectMake(0, 0, containerSize.width, 20);

//			UIEdgeInsets inset = containerView.contentInset;
//			inset.top += 44;
//			containerView.contentInset = inset;
		}
		self.searchingMaskView.hidden = YES;
		self.searchingStatusBarMaskView.hidden = YES;
		[containerView addSubview:self.searchingMaskView];
//		[containerView insertSubview:self.searchingMaskView belowSubview:self];
		[containerView addSubview:self.searchingStatusBarMaskView];
	}
}

- (void)blankClickedWhenSearching:(id)sender
{
	[self resignFirstResponder];
}

- (void)panGestureRecognizerStateUpdate:(UIGestureRecognizer*)recognizer
{
	if(recognizer.state == UIGestureRecognizerStateEnded)//相当于containerView的dragging end
	{
		CGFloat offset = self.containerView.contentOffset.y;
		if(offset<-22 && offset>-60)
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self becomeFirstResponder];
			});
		}
		else
			[self resignFirstResponder];
	}
}

- (void)editingBegan
{
	self.searchingMaskView.hidden = NO;
	self.searchingStatusBarMaskView.hidden = NO;
	self.containerView.panGestureRecognizer.enabled = NO;
	if(autoHideNavBarOfController)
	{
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
		if([autoHideNavBarOfController isKindOfClass:[UINavigationController class]])
		{
			[((UINavigationController*)autoHideNavBarOfController) setNavigationBarHidden:YES animated:YES];
		}
		else
		{
			[autoHideNavBarOfController.navigationController setNavigationBarHidden:YES animated:YES];
		}
	}
	[_containerView bringSubviewToFront:self.searchingMaskView];
	[_containerView bringSubviewToFront:self.searchingStatusBarMaskView];
}

- (void)editingEnded
{
	self.searchingMaskView.hidden = YES;
	self.searchingStatusBarMaskView.hidden = YES;
	self.containerView.panGestureRecognizer.enabled = YES;
	if(autoHideNavBarOfController)
	{
		[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
		if([autoHideNavBarOfController isKindOfClass:[UINavigationController class]])
		{
			[((UINavigationController*)autoHideNavBarOfController) setNavigationBarHidden:NO animated:YES];
		}
		else
		{
			[autoHideNavBarOfController.navigationController setNavigationBarHidden:NO animated:YES];
		}
	}
}

#pragma mark UISearchBarDelegate bridge

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	if([self.outDelegate respondsToSelector:@selector(searchBarShouldBeginEditing:)])
		return [self.outDelegate searchBarShouldBeginEditing:searchBar];
	return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self editingBegan];
	dispatch_async(dispatch_get_main_queue(), ^{
		self.containerView.contentOffset = CGPointMake(0, -20);
	});
	
	if([self.outDelegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)])
		[self.outDelegate searchBarTextDidBeginEditing:searchBar];
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
	[self editingEnded];
	if([self.outDelegate respondsToSelector:@selector(searchBarShouldEndEditing:)])
		return [self.outDelegate searchBarShouldEndEditing:searchBar];
	return YES;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	if([self.outDelegate respondsToSelector:@selector(searchBarTextDidEndEditing:)])
		[self.outDelegate searchBarTextDidEndEditing:searchBar];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if([self.outDelegate respondsToSelector:@selector(searchBar:textDidChange:)])
		[self.outDelegate searchBar:searchBar textDidChange:searchText];
}
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if([self.outDelegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)])
		return [self.outDelegate searchBar:searchBar shouldChangeTextInRange:range replacementText:text];
	return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	if([self.outDelegate respondsToSelector:@selector(searchBarSearchButtonClicked:)])
		[self.outDelegate searchBarSearchButtonClicked:searchBar];
}
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
	if([self.outDelegate respondsToSelector:@selector(searchBarBookmarkButtonClicked:)])
		[self.outDelegate searchBarBookmarkButtonClicked:searchBar];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self resignFirstResponder];
	});
	if([self.outDelegate respondsToSelector:@selector(searchBarCancelButtonClicked:)])
		[self.outDelegate searchBarCancelButtonClicked:searchBar];
}
- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar
{
	if([self.outDelegate respondsToSelector:@selector(searchBarResultsListButtonClicked:)])
		[self.outDelegate searchBarResultsListButtonClicked:searchBar];
}
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	if([self.outDelegate respondsToSelector:@selector(searchBar:selectedScopeButtonIndexDidChange:)])
		[self.outDelegate searchBar:searchBar selectedScopeButtonIndexDidChange:selectedScope];
}

@end
