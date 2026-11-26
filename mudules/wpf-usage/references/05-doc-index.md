# WPF 官方文档索引

> 用途：深入查证与出处核对。全部为 Microsoft Learn 官方文档（learn.microsoft.com）。链接失效时按主题关键词搜索官方站点。

## 基础

- WPF 概述：https://learn.microsoft.com/dotnet/desktop/wpf/overview/
- XAML 概述：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/xaml-overview-wpf/
- 标记扩展与 WPF XAML：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/markup-extensions-and-wpf-xaml/

## 属性系统与事件

- 依赖属性概述：https://learn.microsoft.com/dotnet/desktop/wpf/properties/dependency-properties-overview/
- 依赖属性值优先级（11 层完整表）：https://learn.microsoft.com/dotnet/desktop/wpf/properties/dependency-property-value-precedence/
- 附加属性概述：https://learn.microsoft.com/dotnet/desktop/wpf/properties/attached-properties-overview/
- 路由事件概述：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/routed-events-overview/
- 将事件标记为已处理（Handled）：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/marking-routed-events-as-handled-and-class-handling/

## 数据绑定

- 数据绑定概述：https://learn.microsoft.com/dotnet/desktop/wpf/data/data-binding-overview/
- 绑定模式与 UpdateSourceTrigger：https://learn.microsoft.com/dotnet/desktop/wpf/data/how-to-control-when-the-textbox-text-updates-the-source/
- INotifyDataErrorInfo 校验：https://learn.microsoft.com/dotnet/api/system.componentmodel.inotifydataerrorinfo/
- ObservableCollection：https://learn.microsoft.com/dotnet/api/system.collections.objectmodel.observablecollection-1/

## 命令与 MVVM

- 命令概述：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/commanding-overview/
- CommunityToolkit.Mvvm（ObservableObject/[RelayCommand]/Messenger）：https://learn.microsoft.com/dotnet/communitytoolkit/mvvm/
- 事件转命令（交互触发器）：https://learn.microsoft.com/archive/blogs/johngossman/（Interaction.Triggers 属 Blend SDK，微软维护的 System.Windows.Interactivity/Microsoft.Xaml.Behaviors.Wpf）

## 模板样式资源

- 样式与模板概述：https://learn.microsoft.com/dotnet/desktop/wpf/controls/styles-templates-overview/
- ControlTemplate 示例：https://learn.microsoft.com/dotnet/desktop/wpf/controls/creating-a-controltemplate-for-a-control/
- 资源概述（查找链/Static vs Dynamic）：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/xaml-resources-define/
- DependencyObject 上的 Freezable：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/freezable-objects-overview/

## 线程与异步

- WPF 线程模型：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/threading-model/
- Dispatcher 类：https://learn.microsoft.com/dotnet/api/system.windows.threading.dispatcher/
- async/await 异步编程：https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/async-and-await/
- ConfigureAwait FAQ（官方博客）：https://devblogs.microsoft.com/dotnet/configureawait-faq/

## 性能与调试

- WPF 应用程序性能优化：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/optimizing-wpf-application-performance/
- 绑定诊断（PresentationTraceSources）：https://learn.microsoft.com/dotnet/api/system.diagnostics.presentationtracesources/
- 仅取已处理事件的诊断追踪：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/diagnosing-errornous-bindings/（若失效，搜 "Diagnosing bindings WPF"）

## 互操作与布局

- WPF 与 Win32 互操作：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/wpf-and-win32-interoperation/
- 空域（Airspace）：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/technology-regions-overview/
- 布局系统（Measure/Arrange）：https://learn.microsoft.com/dotnet/desktop/wpf/advanced/layout/

## 生态工具

- Snoop（视觉树/属性/路由实测）：https://github.com/snoopwpf/snoopwpf
- AvalonDock（停靠布局，本项目采用其源码）：https://github.com/Dirkster99/AvalonDock
- Microsoft.Xaml.Behaviors.Wpf（Interaction.Triggers）：https://github.com/microsoft/XamlBehaviorsWpf
