# IDNFramework
为 Foundation 和 UIKit 中的类提供大量 Category 以简化代码编写，同时提供一些自定义类以满足常见的功能开发需求

## 1 安装

### 1.1 通过 CocoaPods 安装
在项目的 Podfile 加入一行：

```
pod 'IDNFramework', '~> 0.0.1'
```
然后执行命令
``` Shell
pod install
```

### 1.2 直接安装源码
下载/克隆 IDNFramework.git 源码，把项目根目录下的 IDNFramework/IDNFramework 整个目录加入到你的项目中


## 2 使用
导入 IDNFramework.h, 然后就可以使用库提供的一些Category方法

``` objective-c
#import "IDNFramework.h"

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.autoResignFirstResponder = YES;  // 点击 self.view 空白处自动收回键盘
}

```
**建议** 将 `#import "IDNFramework.h"` 放在项目的 *.pch 文件中以加快项目编译速度
