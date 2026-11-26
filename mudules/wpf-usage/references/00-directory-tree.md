# WPF 技术目录树

> 来源：Microsoft 官方 WPF 模板与 MVVM 社区标准（learn.microsoft.com/dotnet/desktop/wpf、CommunityToolkit.Mvvm 文档）。本文件是"技术方案 → 目录落地"的依据，与宿主项目 `specs/项目目录结构.md` 冲突时以项目定制为准。

## 1. 标准 MVVM 工程树（单应用）

```text
MyApp/
├── src/
│   ├── MyApp/                              # ① WPF 应用（net8.0-windows / net48 双选）
│   │   ├── App.xaml / App.xaml.cs          #    启动、全局资源（MergedDictionaries）、异常兜底
│   │   ├── AssemblyInfo.cs                 #    ThemeInfo 特性（控件库主题查找声明）
│   │   ├── Views/                          #    窗口与用户控件（视觉层，code-behind 极薄）
│   │   │   ├── MainWindow.xaml(.cs)
│   │   │   └── Dialogs/
│   │   ├── ViewModels/                     #    ViewModel（CommunityToolkit.Mvvm）
│   │   │   ├── ViewModelBase.cs            #    （可选）公共基类/服务注入封装
│   │   │   └── <Feature>ViewModel.cs
│   │   ├── Models/                         #    业务模型（UI 直接绑定时继承 ObservableObject）
│   │   ├── Services/                       #    服务接口 + 实现（构造注入）
│   │   │   ├── I<Xxx>Service.cs
│   │   │   └── <Xxx>Service.cs
│   │   ├── Controls/                       #    自定义控件（无外观逻辑的 templated control）
│   │   │   ├── <Xxx>Control.cs             #    ← 依赖属性定义在这里（类内部）
│   │   │   └── Themes/generic.xaml         #    ← 控件默认模板（无 Key，DefaultStyleKey 模式）
│   │   ├── Behaviors/                      #    附加属性行为 / 事件转命令
│   │   ├── Converters/                     #    IValueConverter / IMultiValueConverter
│   │   ├── Messages/                       #    Messenger 消息契约（纯数据类）
│   │   ├── Themes/                         #    应用级资源组织
│   │   │   ├── Basic/                      #      设计令牌：Colors / Brushes / Fonts / Sizes
│   │   │   ├── Styles/                     #      控件样式字典（<Xxx>Theme.xaml）
│   │   │   └── Dark.xaml / Light.xaml      #      主题（换肤 = 换这层字典条目）
│   │   └── Resources/                      #    图片 / 字体 / 图标
│   └── MyApp.Core / MyApp.Contracts/       # ② 业务/契约类库（可多目标 net48;net8.0，无 UI 依赖）
├── tests/
│   └── MyApp.Tests/                        #    ViewModel 单测（不引用 UI 类型）
└── MyApp.sln
```

**大项目拆分建议**（对应大型 WPF 产品）：`<App>.Main`（壳）+ `<App>.UI`（控件/样式库）+ `<App>.ViewModel`（VM）+ `<App>.<Domain>`（业务库）分层成独立 csproj，依赖方向：Main → UI/ViewModel → Domain。

## 2. "放哪里"决策表

| 产物 | 归属目录 | 说明 |
|---|---|---|
| 依赖属性 | 自定义控件类内部（Controls/） | DP 是控件 API 的一部分，跟随控件类 |
| 附加属性 | Behaviors/（行为类）或 Controls/ | 纯行为注入（拖拽/校验提示）放 Behaviors |
| 值转换器 | Converters/ | 一个文件一个转换器，无状态 |
| 控件模板（自定义控件默认皮） | Controls/Themes/generic.xaml | 控件库约定；应用内一次性模板可放 Themes/ |
| 样式（隐式/命名） | Themes/Styles/<Xxx>Theme.xaml | 经 App.xaml MergedDictionaries 引入 |
| 颜色/字号/间距令牌 | Themes/Basic/ | 换肤只动这一层 |
| 消息类 | Messages/ | 与 Messenger 注册代码配对 |
| ViewModel | ViewModels/ | 一个视图一个 VM；对话框可共用 |
| 服务 | Services/ | 接口与实现同目录或接口进 Contracts/ |
| 事件转命令 | Behaviors/ | 不写在 code-behind |
| 图片/图标 | Resources/ 或独立 Icon 资源字典 | 矢量图标可做成 .xaml DrawingImage |

## 3. 反模式（禁止放置）

- ❌ **业务逻辑写进 code-behind**（View.xaml.cs 只允许构造函数/初始化/纯视觉辅助）
- ❌ **VM 继承 DependencyObject / Window / UserControl**——丧失可测试性；VM 必须是 POCO + INPC
- ❌ **样式散落在各 Window.Resources**——重复定义、无法换肤；统一样式进 Themes
- ❌ **业务规则写进转换器/附加属性**——转换器只做"形状变换"，不做业务判断
- ❌ **服务直接 new 在 VM 里**——必须构造注入（可测试性红线）
- ❌ **魔法字符串绑定路径**——用 nameof 或源生成器特性避免拼错
- ❌ **把 UI 类型（Brush/Visibility）放进 Model**——Model 只暴露业务类型，视觉映射交给转换器/样式
- ❌ **MergedDictionaries 顺序随意**——后加载覆盖先加载，令牌层必须在样式层之前

## 4. 与宿主项目的关系

- 本目录树是**默认建议**；宿主项目已有 `specs/项目目录结构.md` 时以其为准。
- 偏离默认树需在技术方案中标注理由（例如遗留模块保留 code-behind 演进过渡）。
