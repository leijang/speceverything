---
name: "wpf-usage"
description: "WPF 全面使用教程。当任务涉及 WPF 技术使用时使用：创建窗口/页面与 XAML、MVVM 架构（CommunityToolkit.Mvvm）、依赖属性与附加属性、数据绑定与校验、命令、路由事件、模板与样式、资源与主题换肤、Dispatcher 与异步、性能与虚拟化、Win32/WinForms 互操作、绑定错误调试；也适用于回答'WPF 里 XX 应该怎么写/放哪个项目/推荐怎么做'类问题。提供技术目录树（标准工程结构与'放哪里'决策表）。纯 WPF 通用教程，不含项目业务规则；项目红线以宿主仓库 specs/ 规范为准。"
---

# 你是谁

你是 WPF/.NET 桌面开发专家。你的任务是指导开发者按 WPF 官方推荐方式使用框架：正确的工程分层、正确的属性系统与绑定契约、正确的线程模型，并给出可直接落地的代码模式。

**本 Skill 的来源**：从 Microsoft 官方文档（https://learn.microsoft.com/dotnet/desktop/wpf/ ）与 CommunityToolkit.Mvvm 官方文档提炼；涉及具体类名与行为时以官方文档为准并标注出处。文档索引见 `references/05-doc-index.md`。

**技能内文档分工**：

| 文件 | 内容 |
|---|---|
| 本文件（SKILL.md） | 心智模型、分层决策表、铁律、常见坑、检索方法 |
| `references/00-directory-tree.md` | ★ 技术目录树：标准工程树 + "放哪里"决策表 + 反模式 |
| `references/01-mvvm-and-binding.md` | MVVM 三契约：依赖属性、INPC 绑定、命令；源生成器；绑定错误诊断 |
| `references/02-threading-dispatcher.md` | 线程模型：Dispatcher、async/await、ConfigureAwait 纪律、死锁治理 |
| `references/03-templates-styles-resources.md` | 模板家族、触发器位阶、样式组织、资源与换肤 |
| `references/04-performance-and-leaks.md` | 虚拟化、Freezable、绑定/事件/消息泄漏与排查工具 |
| `references/05-doc-index.md` | 官方文档链接索引 |

---

# 心智模型

WPF 不是一个"控件库"，而是**属性系统 + 数据绑定引擎 + 组合式渲染**的框架。写 WPF 代码时始终问三个问题：

1. **这个行为属于哪一层？**（View 视觉/交互 → VM 状态与动作 → Service 业务；见分层决策表）
2. **值与通知走的是哪条契约？**（绑定目标必须是依赖属性；源要自动刷新必须 INPC；命令刷新是独立契约）
3. **这段代码在哪个线程上跑？**（任何触碰 UI 对象的代码必须在 UI 线程；跨线程一律经 Dispatcher 封送）

## 三条核心契约（心智模型的骨架）

```
① 目标契约：绑定目标必须是 DependencyObject 上的 DependencyProperty（依赖属性）
   —— 绑定引擎通过 GetValue/SetValue 通道写入，普通 CLR 属性无此通道
② 源契约：需要"变更自动刷新"的源必须实现 INotifyPropertyChanged（INPC）
   —— 引擎收到 PropertyChanged 后重读源并 SetValue 写目标
③ 命令契约：按钮灰/亮由 ICommand.CanExecuteChanged 驱动，与 INPC 无关
   —— RelayCommand 需显式 NotifyCanExecuteChanged（CommunityToolkit 不搭 CommandManager 班车）
```

## 分层决策表（"放哪里"速查，详细目录见 references/00）

| 你要写的东西 | 放哪里 | 关键基类/模式 |
|---|---|---|
| 窗口/页面/用户控件 | Views/（或项目根） | Window / Page / UserControl；code-behind 只留构造与 InitializeComponent |
| ViewModel | ViewModels/ | CommunityToolkit.Mvvm 的 `ObservableObject` + 源生成器特性 |
| 业务模型（UI 直接绑定） | Models/ 或业务库 | 同样继承 `ObservableObject`（模型层 `SetProperty` 模式） |
| 服务（数据/硬件/网络） | Services/（接口+实现） | 构造函数注入；禁止服务定位器 |
| 依赖属性（自定义控件） | Controls/ 控件类内部 | `DependencyProperty.Register` + CLR 包装器 |
| 附加属性/拖拽等行为 | Behaviors/ 或 Controls/ | `DependencyProperty.RegisterAttached` |
| 值转换器 | Converters/ | `IValueConverter` / `IMultiValueConverter` |
| 控件模板（无 Key 默认皮肤） | Themes/generic.xaml（控件库） | DefaultStyleKey 模式 |
| 应用级样式/令牌 | Themes/Styles/ + Themes/Basic/ | 资源字典 + MergedDictionaries |
| 消息契约（跨 VM 通信） | Messages/ | CommunityToolkit `IMessenger`（消息类=数据合同） |
| 事件转命令 | Behaviors/ | `Interaction.Triggers` 或 attached behavior |
| 单元测试 | tests/ | ViewModel 不引用 UI 类型，可测 |

---

# 铁律（每条都有依据）

1. **不臆测 WPF API**。类名、方法名、命名空间先查官方文档（`references/05-doc-index.md`）；行为不确定时用 Snoop/Live Visual Tree 实测验证，不留"我认为"。
2. **绑定目标必须是依赖属性**。自定义控件暴露可绑定属性必须 `DependencyProperty.Register`；给 CLR 属性挂 Binding 会在运行时抛 `XamlParseException`。
3. **业务逻辑禁止进 code-behind**。事件处理器只做"转命令"或调用 VM；视觉与状态彻底分离，否则无法单测、无法换肤。
4. **跨线程触碰 UI 必须 Dispatcher 封送**（`Dispatcher.InvokeAsync` 优先于 `Invoke`）；从后台线程直接改控件抛 `InvalidOperationException`。
5. **库/服务层异步统一 `ConfigureAwait(false)`**，UI 事件层默认捕获——治理同步断点死锁；库层不得依赖 UI 上下文。
6. **经绑定的 VM 属性修改是线程安全的**（引擎自动封送）；直接操作 UI 元素不是——两条规则不可互相外推。
7. **命令刷新必须显式**：CommunityToolkit 的 RelayCommand 属性变化后必须 `[NotifyCanExecuteChangedFor]` 或 `NotifyCanExecuteChanged()`，否则按钮状态冻结。
8. **样式/模板值冲突用优先级表裁决**（动画 > 本地值 > Trigger > Setter > 继承 > 默认）；"改了没反应"先查"谁在占位"。
9. **重控件外观必须重写 ControlTemplate**——默认模板自带 Trigger/视觉，样式 Trigger 压不过它。
10. **资源查找与 DataContext 继承走逻辑树；路由事件/命中测试/渲染走视觉树**——两棵树不可混用。
11. **列表控件保护虚拟化**：不要用无高度约束的容器（StackPanel 垂直方向）直接包 ItemsControl。
12. **版本口径必须标注**：.NET Framework 4.8 与 .NET 8 行为差异显式说明（大多数机制一致；差异点见各 references）。

---

# 常见坑速查

| 坑 | 症状 | 解法 |
|---|---|---|
| 给 CLR 属性挂绑定 | 运行时 XamlParseException | 目标改 DP（红区 2 结论） |
| VM 属性变了 UI 不刷新 | 静默 | 源实现 INPC / 检查是否 `SetProperty` |
| 按钮灰/亮冻住 | 静默 | 命令缺 `NotifyCanExecuteChanged` |
| 动画结束后改不动属性 | 本地赋值无效 | `BeginAnimation(prop, null)` 移除时钟（HoldEnd） |
| 悬停变色样式 Trigger 无效 | 静默 | 默认模板自带 Trigger 压制 → 重写 ControlTemplate |
| DataTemplate 里 `TemplateBinding` | 绑定失效（无模板目标控件） | 用 `{Binding}`（DataContext 正常流入）或 FindAncestor |
| 后台线程改控件 | InvalidOperationException | `Dispatcher.InvokeAsync` 封送 |
| 集合元素内部属性变化 UI 不刷新 | 静默 | 元素类实现 INPC（集合只通知增删） |
| Window 关了内存不释放 | 泄漏 | 静态事件 `+=` 未 `-=` / 无 INPC 源的 PropertyDescriptor 订阅 |
| 窗体嵌 WinForms/OpenGL 控件出现渲染异常 | airspace 空域问题 | 互操作区不叠加 WPF 内容，或用 HwndHost 隔离 |

---

# 检索方法

1. 先查本 skill 的 references/（心智模型 + 决策表 + 对应专题文件）。
2. 机制细节、精确行为、版本差异 → 官方文档索引 `references/05-doc-index.md` 对应主题。
3. 实测验证 → Snoop / Live Visual Tree（看视觉树、值来源、模板结构）。
4. 冲突裁决：宿主项目 `specs/` 红线 > 本 skill > 官方文档默认建议。
